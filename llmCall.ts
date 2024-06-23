import  {
  GoogleGenerativeAI,
  HarmCategory,
  HarmBlockThreshold,
  EnhancedGenerateContentResponse,
  GenerationConfig,
} from "@google/generative-ai";

const apiKey = process.env.GEMINI_API_KEY;
if (!apiKey) {
  throw new Error("no gemini api key")
}
const genAI = new GoogleGenerativeAI(apiKey);

const model = genAI.getGenerativeModel({
  model: "gemini-1.5-flash",
  systemInstruction: `You are an Expert in POSIX Thread Model and Linux API, including sync prototype, atomic, CPU cache and memory corruption. You will check the input source code, point the issues including: wrong memory order of atomic variables read and write; dead lock; non-thread safe API uses in thread scope. Response in JSON format: 
{
  "code": $code,
  "cwe_name": $cwe_name,
  "sync_issue": $sync_issue
}`
})

const generationConfig: GenerationConfig = {
  temperature: 0,
  topP: 0.95,
  topK: 64,
  maxOutputTokens: 8192,
  responseMimeType: "text/plain",
};

export async function checkContent(code: string): Promise<EnhancedGenerateContentResponse> {
  const chatSession = model.startChat({
    generationConfig,
    history: [],
  });

  const result = await chatSession.sendMessage(code);
  return result.response
}
