import {HarmBlockThreshold, HarmCategory, VertexAI} from "@google-cloud/vertexai";

// Initialize Vertex with your Cloud project and location
const vertex_ai = new VertexAI({project: 'braided-case-416903', location: 'us-central1'});
const model = 'gemini-1.5-flash-001';

// Instantiate the models
export const generativeModel = vertex_ai.preview.getGenerativeModel({
  model: model,
  generationConfig: {
    'maxOutputTokens': 8192,
    'temperature': 0,
    'topP': 0.95,
  },
  safetySettings: [
    {
        'category': HarmCategory.HARM_CATEGORY_HARASSMENT,
        'threshold': HarmBlockThreshold.BLOCK_NONE
    },
    {
        'category': HarmCategory.HARM_CATEGORY_HATE_SPEECH,
        'threshold': HarmBlockThreshold.BLOCK_NONE
    },
    {
        'category': HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
        'threshold': HarmBlockThreshold.BLOCK_NONE
    },
    {
        'category': HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT,
        'threshold': HarmBlockThreshold.BLOCK_NONE
    }
  ],
});


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
