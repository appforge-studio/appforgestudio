import { GoogleGenerativeAI } from "@google/generative-ai";
import { env } from "@env";
import { getDrizzle } from "@database/postgres";
import { components } from "@database/schema/components";
import { svgs } from "@database/schema/svgs";
import { aiDesignCache } from "@database/schema/ai_cache";
import { aiDesignSessions, aiDesignMessages } from "@database/schema/ai_sessions";
import { eq, asc } from "drizzle-orm";
import { ulid } from "ulidx";

export class AiService {
  private static genAI = new GoogleGenerativeAI(env.GOOGLE_STUDIO_API_KEY || '');

  static async generateDesign(prompt: string, sessionId?: string, isIteration: boolean = false): Promise<any> {
    const model = this.genAI.getGenerativeModel({
      model: "gemini-flash-latest",
      generationConfig: {
        responseMimeType: "application/json",
      }
    });
    const db = getDrizzle();
    const allComponents = await db.select().from(components);
    const allSvgs = await db.select({ name: svgs.name }).from(svgs);

    const componentTypesList = allComponents.map(c => `"${c.name}"`).join(' | ');
    const svgNamesList = allSvgs.map(s => `"${s.name}"`).join(', ');

    const dynamicPropertiesSchema = allComponents.map((comp: any) => {
      let props: any[] = [];
      try {
        props = JSON.parse(comp.properties);
      } catch (e) {
        return "";
      }

      const propLines = props.map((p: any) => {
        let typeDesc = "any";
        switch (p.type) {
          case 'string': typeDesc = 'string'; break;
          case 'number': typeDesc = 'double'; break;
          case 'boolean': typeDesc = 'boolean'; break;
          case 'color': typeDesc = '"#AARRGGBB" (Hex String)'; break;
          case 'icon': typeDesc = 'string (Material Icon name)'; break;
          default: typeDesc = 'any';
        }
        // MODIFIED: Request simple value directly instead of { value, enable } object
        return `"${p.name}": ${typeDesc}`;
      }).join(',\n        ');

      return `// PROPERTIES FOR "${comp.name}"\n        ${propLines}`;
    }).join('\n\n        ');

    const schemaDescription = `
    You are a UI design generator. Output strictly valid JSON matching this schema for a Flutter app design canvas.
    
    ROOT OBJECT:
    {
      "components": [ ... list of component objects ... ],
      "canvasSize": { "width": 375.0, "height": 812.0 }, // Standard mobile size
      "selectedComponent": null, // Always null initially
      "isDragging": false,
      "isPropertyEditorVisible": false
    }

    COMPONENT OBJECT:
    {
      "id": "unique_string_id",
      "type": ${componentTypesList},
      "x": double (position),
      "y": double (position),
      "resizable": true,
      "properties": {
        // Use simple direct values for properties
        
        // DYNAMICALLY GENERATED PROPERTIES FROM DATABASE
        ${dynamicPropertiesSchema}
      }
    }

    IMPORTANT RULES:
    1. Every component MUST have a unique "id".
    2. All properties MUST be simple direct values (string, number, boolean, or hex string for colors).
    3. Colors MUST be Hex strings (e.g. "#FF0000" or "#AARRGGBB").
    4. For any "icon" property, you MUST use ONLY one of these valid names: [${svgNamesList}].
    5. Generate a complete, beautiful design based on the user prompt: "${prompt}".
    6. Ensure components are positioned logically.
    `;

    let currentPrompt = schemaDescription;
    let attempts = 0;
    const maxAttempts = 3;
    const modelName = "gemini-flash-latest";
    // 1. Check Cache (Only for non-iterations)
    if (!isIteration) {
      try {
        const cached = await db.select()
          .from(aiDesignCache)
          .where(eq(aiDesignCache.prompt, prompt))
          .limit(1);

        if (cached && cached.length > 0) {
          const entry = cached[0];
          if (entry) {
            console.log("🚀 Cache HIT for prompt:", prompt);
            return JSON.parse(entry.designJson);
          }
        }
        console.log("🌑 Cache MISS for prompt:", prompt);
      } catch (e) {
        console.error("⚠️ Cache lookup error:", e);
      }
    }

    console.log("----------------------------------------------------------------");
    console.log("🤖 GENERATED AI PROMPT:");
    console.log(currentPrompt);
    console.log("----------------------------------------------------------------");

    while (attempts < maxAttempts) {
      try {
        console.log(`🤖 AI Generation Attempt ${attempts + 1}/${maxAttempts}`);
        console.log("⏳ Waiting for Gemini API response...");
        const result = await model.generateContent(currentPrompt);
        console.log("✅ Received response from Gemini API");

        console.log("⏳ Extracting text from response...");
        const responseText = result.response.text();
        console.log("✅ Text extracted");

        let json: any;
        try {
          console.log("⏳ Parsing JSON...");
          json = JSON.parse(responseText);
          console.log("✅ JSON parsed successfully");
        } catch (e) {
          console.error("❌ Failed to parse JSON:", responseText);
          throw new Error("Invalid JSON returned by AI");
        }

        // basic validation
        const errors = this.validateDesignJson(json);
        if (errors.length === 0) {
          // 2. Save to Cache (ONLY for initial prompts, NOT for iterations or fixing prompts)
          if (!isIteration && attempts === 0) {
            try {
              await db.insert(aiDesignCache).values({
                id: ulid(),
                prompt: prompt,
                designJson: JSON.stringify(json),
                modelUsed: modelName,
              }).onConflictDoUpdate({
                target: aiDesignCache.prompt,
                set: { designJson: JSON.stringify(json), modelUsed: modelName }
              });
              console.log("✅ Saved to cache (initial successful attempt)");
            } catch (e) {
              console.error("⚠️ Failed to save to cache:", e);
            }
          } else if (attempts > 0) {
            console.log("ℹ️ Skipping cache save for fixing prompt (attempt > 0)");
          } else if (isIteration) {
            console.log("ℹ️ Skipping cache save for iteration prompt");
          }

          // 3. Record in Session if provided
          if (sessionId) {
            try {
              const db = getDrizzle();
              // Ensure session exists
              await db.insert(aiDesignSessions).values({ id: sessionId }).onConflictDoNothing();

              // Record user prompt
              await db.insert(aiDesignMessages).values({
                id: ulid(),
                sessionId: sessionId,
                role: 'user',
                content: prompt,
              });

              // Record AI response
              await db.insert(aiDesignMessages).values({
                id: ulid(),
                sessionId: sessionId,
                role: 'assistant',
                content: JSON.stringify(json),
              });
              console.log("✅ Recorded messages in session:", sessionId);
            } catch (e) {
              console.error("⚠️ Failed to record session message:", e);
            }
          }

          return json;
        }

        console.warn("⚠️ Validation Errors:", errors);

        // Add errors to prompt and retry
        currentPrompt = `
        The previous JSON had the following errors:\n${errors.join('\n')}\n
        Please fix these errors and return the valid JSON again.
        Original Prompt: ${schemaDescription}
        `;

        attempts++;
      } catch (error) {
        console.error("❌ AI Generation Error:", error);
        attempts++;
        if (attempts < maxAttempts) {
          console.log("Waiting 5 seconds before retry...");
          await new Promise(resolve => setTimeout(resolve, 5000));
        }
      }
    }

    throw new Error("Failed to generate valid design after multiple attempts");
  }

  static async iterateDesign(sessionId: string, prompt: string): Promise<any> {
    const db = getDrizzle();

    // 1. Fetch History
    const history = await db.select()
      .from(aiDesignMessages)
      .where(eq(aiDesignMessages.sessionId, sessionId))
      .orderBy(asc(aiDesignMessages.createdAt));

    if (history.length === 0) {
      // If no history, just do a normal generation (which will be cached)
      return this.generateDesign(prompt, sessionId, false);
    }

    // 2. Find last design
    let lastDesignJson = "";
    for (let i = history.length - 1; i >= 0; i--) {
      const entry = history[i];
      if (entry && entry.role === 'assistant') {
        lastDesignJson = entry.content;
        break;
      }
    }

    // 3. Construct Contextual Prompt
    const contextPrompt = `
    The user is iterating on a previous design.
    ${lastDesignJson ? `PREVIOUS DESIGN JSON:\n${lastDesignJson}\n` : ''}
    
    USER FEEDBACK / REQUEST:
    "${prompt}"
    
    Based on the previous design and the user's feedback, provide an updated, corrected JSON.
    Maintain the overall structure but apply the requested changes carefully.
    `;

    // 4. Generate using context (passed as isIteration: true to avoid caching)
    return this.generateDesign(contextPrompt, sessionId, true);
  }

  static validateDesignJson(json: any): string[] {
    const errors: string[] = [];

    if (!json.components || !Array.isArray(json.components)) {
      errors.push("Root object missing 'components' array");
      return errors; // Critical failure
    }

    json.components.forEach((comp: any, index: number) => {
      if (!comp.type) errors.push(`Component[${index}] missing type`);

      // Auto-parse x and y if they are strings
      if (typeof comp.x === 'string') {
        const parsed = parseFloat(comp.x);
        if (!isNaN(parsed)) comp.x = parsed;
      }
      if (typeof comp.y === 'string') {
        const parsed = parseFloat(comp.y);
        if (!isNaN(parsed)) comp.y = parsed;
      }

      if (typeof comp.x !== 'number') errors.push(`Component[${index}] invalid x`);
      if (typeof comp.y !== 'number') errors.push(`Component[${index}] invalid y`);

      if (!comp.properties) {
        errors.push(`Component[${index}] missing properties`);
      } else {
        // Auto-parse property values if they are strings that look like numbers
        Object.keys(comp.properties).forEach(key => {
          const val = comp.properties[key];
          if (typeof val === 'string' && val.trim() !== '' && !isNaN(Number(val)) && !val.startsWith('#')) {
            // If it's a numeric string and not a color hex, attempt to parse it
            comp.properties[key] = parseFloat(val);
          }
        });
      }
    });

    return errors;
  }
}
