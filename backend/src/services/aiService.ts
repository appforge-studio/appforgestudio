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

  static async generateDesign(prompt: string, sessionId?: string, isIteration: boolean = false, apiKey?: string): Promise<any> {
    const db = getDrizzle();
    const modelName = "gemini-flash-latest";

    // Initialize AI client (use provided key or fallback to default)
    const client = apiKey
      ? new GoogleGenerativeAI(apiKey)
      : this.genAI;

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
        return `"${p.name}": ${typeDesc}`;
      }).join(',\n        ');

      return `// PROPERTIES FOR "${comp.name}"\n        ${propLines}`;
    }).join('\n\n        ');

    // --- STEP 1: GENERATE DESIGN PLAN ---
    console.log("🎨 STEP 1: Generating Design Plan...");
    const planModel = client.getGenerativeModel({ model: modelName });
    const planPrompt = `
    You are an expert UI/UX designer. Your task is to create a detailed design plan for a Flutter application based on the user's request.
    
    USER REQUEST: "${prompt}"
    
    AVAILABLE COMPONENTS: [${allComponents.map(c => c.name).join(', ')}]
    
    In your plan, describe:
    1. The overall layout and structure.
    2. Which components you will use and why.
    3. The positioning (x, y) and sizing of these components.
    4. The color palette and specific property values for each component.
    5. How the design fulfills the user's request.
    
    OUTPUT: A detailed textual description of the design.
    `;

    const planResult = await planModel.generateContent(planPrompt);
    const designPlan = planResult.response.text();
    console.log("✅ Design Plan Generated:\n", designPlan);

    // --- STEP 2: GENERATE JSON FROM PLAN ---
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

    PROPERTIES:
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
    5. For any "image" component:
       - You MUST provide a detailed "imagePrompt" string describing what the image should look like.
       - You MUST set the "image" property to "https://placehold.co/600x400?text=Image+Generating...". DO NOT put the prompt in the "image" property.
    6. Strictly follow the DESIGN PLAN provided below.
    `;

    const jsonModel = client.getGenerativeModel({
      model: modelName,
      generationConfig: { responseMimeType: "application/json" }
    });

    let currentPrompt = `
    DESIGN PLAN:
    ${designPlan}

    JSON SCHEMA & RULES:
    ${schemaDescription}
    
    Based on the DESIGN PLAN, generate the final valid JSON.
    `;

    let attempts = 0;
    const maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
        console.log(`🤖 AI JSON Generation Attempt ${attempts + 1}/${maxAttempts}`);
        const result = await jsonModel.generateContent(currentPrompt);
        const responseText = result.response.text();

        let json: any;
        try {
          json = JSON.parse(responseText);
        } catch (e) {
          console.error("❌ Failed to parse JSON:", responseText);
          throw new Error("Invalid JSON returned by AI");
        }

        const errors = this.validateDesignJson(json);
        if (errors.length === 0) {
          // --- HYDRATION STEP: INJECT SVG CONTENT ---
          const svgContentMap = new Map<string, string>();
          const allSvgsFull = await db.select({ name: svgs.name, svg: svgs.svg }).from(svgs);
          for (const s of allSvgsFull) {
            svgContentMap.set(s.name, s.svg);
          }

          json.components.forEach((comp: any) => {
            if (comp.properties && comp.properties.icon) {
              const iconName = comp.properties.icon;
              if (svgContentMap.has(iconName)) {
                console.log(`✨ Injecting SVG content for icon "${iconName}"`);
                comp.properties.icon = svgContentMap.get(iconName);
              } else {
                // Fallback: Check if it's already an SVG (starts with <svg)
                if (!iconName.trim().startsWith('<svg')) {
                  console.warn(`⚠️ Icon "${iconName}" not found in database and is not an SVG string.`);
                  // Optional: Set a default icon or leave it (frontend might break)
                }
              }
            }
          });

          // Cache and Record Session
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
              console.log("✅ Saved to cache");
            } catch (e) {
              console.error("⚠️ Failed to save to cache:", e);
            }
          }

          if (sessionId) {
            try {
              await db.insert(aiDesignSessions).values({ id: sessionId }).onConflictDoNothing();
              await db.insert(aiDesignMessages).values({
                id: ulid(),
                sessionId: sessionId,
                role: 'user',
                content: prompt,
              });
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
        currentPrompt = `
        The previous JSON had the following errors:\n${errors.join('\n')}\n
        Please fix these errors and return the valid JSON again based on the DESIGN PLAN.
        DESIGN PLAN:
        ${designPlan}
        `;

        attempts++;
      } catch (error) {
        console.error("❌ AI Generation Error:", error);
        attempts++;
        if (attempts < maxAttempts) {
          await new Promise(resolve => setTimeout(resolve, 5000));
        }
      }
    }

    throw new Error("Failed to generate valid design after multiple attempts");
  }


  static async iterateDesign(sessionId: string, prompt: string, apiKey?: string): Promise<any> {
    const db = getDrizzle();

    // 1. Fetch History
    const history = await db.select()
      .from(aiDesignMessages)
      .where(eq(aiDesignMessages.sessionId, sessionId))
      .orderBy(asc(aiDesignMessages.createdAt));

    if (history.length === 0) {
      // If no history, just do a normal generation (which will be cached)
      return this.generateDesign(prompt, sessionId, false, apiKey);
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
    return this.generateDesign(contextPrompt, sessionId, true, apiKey);
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

      // CASTING: Ensure properties that should be strings are strings
      if (comp.id !== undefined && typeof comp.id !== 'string') {
        comp.id = String(comp.id);
      }

      if (comp.properties) {
        const stringProps = ['content', 'fontFamily', 'icon', 'text', 'label', 'hint', 'value', 'imagePrompt'];
        stringProps.forEach(prop => {
          if (comp.properties[prop] !== undefined && comp.properties[prop] !== null && typeof comp.properties[prop] !== 'string') {
            console.log(`🪄 Casting property "${prop}" to string:`, comp.properties[prop]);
            comp.properties[prop] = String(comp.properties[prop]);
          }
        });
      }
    });

    return errors;
  }
}
