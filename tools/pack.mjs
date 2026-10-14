// Re-create assets/mermaid.js.z from tools/mermaid.min.js (raw deflate, level 9)
import { deflateRawSync, constants } from "node:zlib";
import { readFileSync, writeFileSync } from "node:fs";
const z = deflateRawSync(readFileSync("tools/mermaid.min.js"), { level: 9, memLevel: 9 });
writeFileSync("assets/mermaid.js.z", z);
console.log(z.length);
