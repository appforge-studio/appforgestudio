import { GoogleGenAI, Type } from "@google/genai";
import { parseSVGPath } from "../utils/vectorUtils";
import { VectorPath } from "../types";

// Helper to ensure API Key exists
const getClient = () => {
  const apiKey = process.env.API_KEY;
  if (!apiKey) {
    throw new Error("API Key is missing from environment variables");
  }
  return new GoogleGenAI({ apiKey });
};

export const generatePathFromPrompt = async (prompt: string): Promise<Partial<VectorPath> | null> => {
  try {
    const ai = getClient();
    
    const systemInstruction = `
      You are an SVG path expert. 
      Your task is to generate a SINGLE SVG 'd' path string based on the user's description.
      The path should be simple, clean, and fit within a 500x500 coordinate system.
      Use only absolute commands: M, L, C, Z.
      Do not use arcs (A) or relative commands (l, c, etc.) to ensure compatibility.
      Return the result as a JSON object containing the 'd' string, a suggested 'fill' color, and 'stroke' color.
    `;

    const response = await ai.models.generateContent({
      model: "gemini-3-flash-preview",
      contents: prompt,
      config: {
        systemInstruction,
        responseMimeType: "application/json",
        responseSchema: {
          type: Type.OBJECT,
          properties: {
            d: { type: Type.STRING, description: "The SVG path data string" },
            fill: { type: Type.STRING, description: "Hex color code for fill" },
            stroke: { type: Type.STRING, description: "Hex color code for stroke" },
            name: { type: Type.STRING, description: "Short name for the shape"}
          },
          required: ["d", "fill", "stroke", "name"]
        }
      }
    });

    if (response.text) {
      const data = JSON.parse(response.text);
      if (data.d) {
          const parsedNodes = parseSVGPath(data.d);
          return {
              nodes: parsedNodes,
              fill: data.fill || '#3b82f6',
              stroke: data.stroke || '#1e3a8a',
              strokeWidth: 2,
              name: data.name || 'AI Shape',
              closed: data.d.toLowerCase().endsWith('z'),
          };
      }
    }
    return null;

  } catch (error) {
    console.error("Gemini Generation Error:", error);
    throw error;
  }
};