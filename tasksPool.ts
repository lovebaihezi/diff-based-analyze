import { sleep } from "./llmCall";

export class TaskPool {
  private currentJobs = 0;
  constructor(private maximumTask: number) {}
  public async wrap<T>(job: () => Promise<T>): Promise<T> {
    while (this.currentJobs >= this.maximumTask) {
      await sleep(10);
    }
    this.currentJobs += 1;
    try {
      const res = await job();
      this.currentJobs -= 1;
      return res;
    } catch (e) {
      this.currentJobs -= 1;
      throw e;
    }
  }
}
