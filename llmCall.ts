import {
  GenerateContentRequest,
  GenerativeModelPreview,
  HarmBlockThreshold,
  HarmCategory,
  VertexAI,
} from "@google-cloud/vertexai";

const vertex_ai = new VertexAI({
  project: "braided-case-416903",
  location: "us-central1",
});

export const GeminiFlash = vertex_ai.preview.getGenerativeModel({
  model: "gemini-1.5-flash-001",
  generationConfig: {
    maxOutputTokens: 8192,
    temperature: 0,
    topP: 0.95,
  },
  safetySettings: [
    {
      category: HarmCategory.HARM_CATEGORY_HARASSMENT,
      threshold: HarmBlockThreshold.BLOCK_NONE,
    },
    {
      category: HarmCategory.HARM_CATEGORY_HATE_SPEECH,
      threshold: HarmBlockThreshold.BLOCK_NONE,
    },
    {
      category: HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
      threshold: HarmBlockThreshold.BLOCK_NONE,
    },
    {
      category: HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT,
      threshold: HarmBlockThreshold.BLOCK_NONE,
    },
  ],
});

export async function checkVulnerabilities(
  model: GenerativeModelPreview,
  code: string,
) {
  const sysPmt = `
You are an Expert in POSIX Thread Model and Linux API, including sync prototype, atomic, CPU cache and memory corruption. You will check the input source code, point the issues including: wrong memory order of atomic variables read and write; dead lock; non-thread safe API uses in thread scope. `;
  const req: GenerateContentRequest = {
    systemInstruction: sysPmt,
    contents: [{ role: "user", parts: [{ text: code }] }],
  };
  const res = await model.generateContent(req);
  const { candidates } = res.response;
  if (candidates) {
    for (const candidate of candidates) {
      console.log(candidate.content);
    }
  }
}

// async function generateContent() {
//   const req = {
//     contents: [
//     ],
//   };
//
//   const streamingResp = await generativeModel.generateContentStream(req);
//
//   for await (const item of streamingResp.stream) {
//     process.stdout.write('stream chunk: ' + JSON.stringify(item) + '\n');
//   }
//
//   process.stdout.write('aggregated response: ' + JSON.stringify(await streamingResp.response));
// }
