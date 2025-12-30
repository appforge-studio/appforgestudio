import { Ollama } from 'ollama';

// Ollama client configuration
export interface OllamaConfig {
    host?: string;
    model?: string;
    temperature?: number;
    top_p?: number;
    num_predict?: number;
    timeout?: number; // Timeout in milliseconds
}

// Default Ollama configuration
const DEFAULT_CONFIG: Required<OllamaConfig> = {
    host: 'http://localhost:11434',
    model: 'gpt-oss:20b',
    temperature: 0.7,
    top_p: 0.9,
    num_predict: 1000,
    timeout: 1200000, // 10 minutes timeout
};

// Ollama response interface
export interface OllamaResponse {
    success: boolean;
    content?: string;
    error?: string;
    actualResponse?: string; // The actual response field from Ollama
    thinkingContent?: string; // The thinking field from Ollama
    contentSource?: string; // Which field was used as the main content
}


/**
 * Call Ollama API using the official client
 * @param prompt - The prompt to send to the model
 * @param config - Optional configuration overrides
 * @returns Promise<OllamaResponse>
 */
export async function callOllama(
    prompt: string, 
    config: OllamaConfig = {}
): Promise<OllamaResponse> {
    try {
        // Merge with default configuration
        const finalConfig = { ...DEFAULT_CONFIG, ...config };


        // Initialize Ollama client
        const ollama = new Ollama({
            host: finalConfig.host
        });
        
        // Create a promise that resolves with the Ollama response
        const ollamaPromise = ollama.generate({
            model: finalConfig.model,
            prompt: prompt,
            stream: false,
            options: {
                temperature: finalConfig.temperature,
                top_p: finalConfig.top_p,
                num_predict: finalConfig.num_predict,
            }
        });

        // Create a timeout promise
        const timeoutPromise = new Promise<never>((_, reject) => {
            setTimeout(() => {
                reject(new Error(`Request timed out after ${finalConfig.timeout}ms`));
            }, finalConfig.timeout);
        });


        // Race between the Ollama request and timeout
        let response;
        try {
            response = await Promise.race([ollamaPromise, timeoutPromise]);
        } catch (error) {
            throw error;
        }
        if (!response) {
            throw new Error('Null response from Ollama');
        }

        // Only use the response field, ignore thinking
        const responseText = response.response && response.response.trim() ? response.response.trim() : '';
        
        if (!responseText) {
            throw new Error('Empty response from Ollama');
        }
        
        return {
            success: true,
            content: responseText,
        };
    } catch (error) {
        // Provide more specific error messages
        let errorMessage = 'Unknown error occurred';
        if (error instanceof Error) {
            if (error.message.includes('ECONNREFUSED')) {
                errorMessage = `Cannot connect to Ollama. Make sure Ollama is running on ${config.host || DEFAULT_CONFIG.host}`;
            } else if (error.message.includes('model')) {
                errorMessage = `Model "${config.model || DEFAULT_CONFIG.model}" not found. Make sure the model is installed in Ollama`;
            } else if (error.message.includes('timed out')) {
                errorMessage = `Request timed out after ${config.timeout || DEFAULT_CONFIG.timeout}ms. Try reducing num_predict or using a faster model.`;
            } else {
                errorMessage = error.message;
            }
        }
        
        return {
            success: false,
            error: errorMessage,
        };
    }
}

// Chat message format for Ollama chat API
export interface OllamaChatMessage {
    role: 'system' | 'user' | 'assistant';
    content: string;
}

/**
 * Call Ollama chat API with a sequence of messages
 */
export async function callOllamaChat(
    messages: OllamaChatMessage[],
    config: OllamaConfig = {}
): Promise<OllamaResponse> {
    try {
        const finalConfig = { ...DEFAULT_CONFIG, ...config };

        const ollama = new Ollama({ host: finalConfig.host });

        const ollamaPromise = ollama.chat({
            model: finalConfig.model,
            messages,
            stream: false,
            options: {
                temperature: finalConfig.temperature,
                top_p: finalConfig.top_p,
                num_predict: finalConfig.num_predict,
            }
        });

        const timeoutPromise = new Promise<never>((_, reject) => {
            setTimeout(() => {
                reject(new Error(`Request timed out after ${finalConfig.timeout}ms`));
            }, finalConfig.timeout);
        });

        let response;
        try {
            response = await Promise.race([ollamaPromise, timeoutPromise]);
        } catch (error) {
            throw error;
        }
        if (!response) {
            throw new Error('Null response from Ollama');
        }

        const responseText = response.message && response.message.content && response.message.content.trim() ? response.message.content.trim() : '';
        if (!responseText) {
            throw new Error('Empty response from Ollama');
        }

        return {
            success: true,
            content: responseText,
        };
    } catch (error) {
        let errorMessage = 'Unknown error occurred';
        if (error instanceof Error) {
            if (error.message.includes('ECONNREFUSED')) {
                errorMessage = `Cannot connect to Ollama. Make sure Ollama is running on ${config.host || DEFAULT_CONFIG.host}`;
            } else if (error.message.includes('model')) {
                errorMessage = `Model "${config.model || DEFAULT_CONFIG.model}" not found. Make sure the model is installed in Ollama`;
            } else if (error.message.includes('timed out')) {
                errorMessage = `Request timed out after ${config.timeout || DEFAULT_CONFIG.timeout}ms. Try reducing num_predict or using a faster model.`;
            } else {
                errorMessage = error.message;
            }
        }

        return {
            success: false,
            error: errorMessage,
        };
    }
}

