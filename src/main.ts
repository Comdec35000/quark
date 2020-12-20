import { File } from './utils/file.ts';
import { Interpreter } from './core/interpreter.ts';

async function main(): Promise<void> {
  // Getting sample code content and interpreting it
  const script: string = await File.read('sample/index.qrk');
  Interpreter.run(script);
}

await main();
