import { resolve, join, dirname } from "path";
import { mkdir, writeFile } from "fs/promises";

function getProjectRoot(): string {
    const cwd = process.cwd();
    if (cwd.endsWith('backend')) {
        return resolve(cwd, '..');
    }
    return cwd;
}

export function resolveTypePath(name: string, structure: string) {
    // Structure: 'enum' | 'object'
    const subDir = structure === 'enum' ? 'enums' : 'objects';
    const rootDir = getProjectRoot();

    // Go up into frontend
    const absoluteDir = resolve(rootDir, `./frontend/lib/models/${subDir}`);
    const absolutePath = join(absoluteDir, `${name}.dart`);

    // Path relative to project root
    const relativePath = `/frontend/lib/models/${subDir}/${name}.dart`;

    return { absolutePath, relativePath };
}

export function generateTypeContent(className: string, structure: string, enumValues: string[] = [], rawCode: string = ""): string {
    if (structure === 'enum') {
        const values = enumValues.length > 0 ? enumValues : ['placeholder'];
        return `enum ${className} {\n${values.map(v => `  ${v},`).join('\n')}\n}`;
    } else {
        return rawCode || `class ${className} {
  final String id;
  // Add properties here
  
  const ${className}({required this.id});
}`;
    }
}

export async function writeTypeFile(absolutePath: string, content: string) {
    await mkdir(dirname(absolutePath), { recursive: true });
    await writeFile(absolutePath, content, 'utf8');
}
