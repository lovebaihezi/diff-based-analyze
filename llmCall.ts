import  {
  GoogleGenerativeAI,
  HarmCategory,
  HarmBlockThreshold,
  EnhancedGenerateContentResponse,
  GenerationConfig,
  StartChatParams,
} from "@google/generative-ai";
import logger from "./logger";

const apiKey = process.env.GEMINI_API_KEY;
if (!apiKey) {
  throw new Error("no gemini api key")
}
const genAI = new GoogleGenerativeAI(apiKey);

const model = genAI.getGenerativeModel({
  model: "gemini-1.5-flash",
  systemInstruction: `You are an Expert in POSIX Thread Model and Linux API, including sync prototype, atomic, CPU cache and memory corruption. You will check the input source code, point the issues including: wrong memory order of atomic variables read and write; dead lock; non-thread safe API uses in thread scope. Response in JSON format: 
{
  "codesContainsIssue": {
    "type": "array",
    "value": [
      {
        "codeWithIssue": {
          "value": "...",
          "type": "string",
        },
        "CWE": {
          "value": "...",
          "type": "string",
        },
        "threadSyncIssue": {
          "value": "...",
          "type": "string",
        },
      },
      ...
    ]
  }
}`
})

const generationConfig: GenerationConfig = {
  temperature: 0,
  topP: 0.95,
  topK: 64,
  maxOutputTokens: 8192,
  responseMimeType: "application/json",
};

export function sleep(s: number): Promise<null> {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve(null)
    }, s * 1000)
  })
}

interface Options extends GenerationConfig{
  history: StartChatParams['history']
  timeout: number
}

export async function checkContent(code: string, options?: Options): Promise<EnhancedGenerateContentResponse | null> {
  const chatSession = model.startChat({
    generationConfig,
    ...options
  });

  const result = await Promise.race([chatSession.sendMessage(code), sleep(options?.timeout ?? 300)]);
  if (result) {
    return result.response
  }
  logger.error("call llm timeout")
  return null
}
