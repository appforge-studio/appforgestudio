import { promises as fs } from 'fs';
import { join, resolve } from 'path';

function getProjectRoot(): string {
  const cwd = process.cwd();
  if (cwd.endsWith('backend')) {
    return resolve(cwd, '..');
  }
  return cwd;
}

export const COMPONENT_DIR_REL = './frontend/lib/components';
export const ENUMS_FILE_REL = './frontend/lib/models/enums.dart';
export const FACTORY_FILE_REL = './frontend/lib/components/component_properties_factory.dart';
export const COMPONENTS_EXPORT_FILE_REL = './frontend/lib/components/components.dart';

export interface ComponentProperty {
  name: string;
  type: 'string' | 'number' | 'boolean' | 'color' | 'icon';
  initialValue: any;
  group?: string;
  displayName?: string;
}

// Helper to convert PascalCase/camelCase to snake_case for filenames if needed, 
// though we usually assume the component name passed in is already suitable for folder names.
// But for class names, we usually start with upper case.

function toPascalCase(str: string): string {
  return str.replace(/(^\w|-\w)/g, clearAndUpper);
}


function fillTemplate(template: string, replacements: Record<string, string>): string {
  return template.replace(/\{\{(\w+)\}\}/g, (match, key) => {
    return replacements[key] || match;
  });
}

async function readAndFillTemplate(templatePath: string, replacements: Record<string, string>): Promise<string> {
  const template = await fs.readFile(templatePath, 'utf8');
  return fillTemplate(template, replacements);
}

function clearAndUpper(text: string): string {
  return text.replace(/-/, "").toUpperCase();
}


/**
 * Scans the frontend/lib/components directory and returns a list of available components.
 * A component is valid if it has a directory containing 'component.dart' and 'properties.dart'.
 */
async function getAvailableComponents(rootDir: string): Promise<{ name: string; className: string }[]> {
  const componentsDir = join(rootDir, 'frontend', 'lib', 'components');

  if (!await fs.stat(componentsDir).catch(() => false)) {
    return [];
  }

  const entries = await fs.readdir(componentsDir, { withFileTypes: true });
  const components: { name: string; className: string }[] = [];

  for (const entry of entries) {
    if (entry.isDirectory()) {
      const compPath = join(componentsDir, entry.name);
      try {
        await fs.access(join(compPath, 'component.dart'));
        await fs.access(join(compPath, 'properties.dart'));
        // Assume className is PascalCase of directory name
        components.push({ name: entry.name, className: toPascalCase(entry.name) });
      } catch (e) {
        // Not a valid component directory, skip
      }
    }
  }

  return components;
}


export async function generateComponentFactories() {
  const rootDir = getProjectRoot();
  const components = await getAvailableComponents(rootDir);
  const templatesDir = join(rootDir, 'backend', 'src', 'templates', 'components');

  // Sort components for deterministic output
  components.sort((a, b) => a.name.localeCompare(b.name));

  // Data for Placeholders
  const imports = components.map(c =>
    `import '../components/${c.name}/component.dart';\nimport '../components/${c.name}/properties.dart';`
  ).join('\n');

  const componentTypeEnum = components.map(c => c.name).join(', ');

  const casesCreateComponent = components.map(c =>
    `      case ComponentType.${c.name}:
        return ${c.className}Component(id: componentId, x: x, y: y);`
  ).join('\n');

  const casesFromJson = components.map(c =>
    `      case ComponentType.${c.name}:
        return ${c.className}Component.fromJson(json);`
  ).join('\n');

  const casesGetDefaultProperties = components.map(c =>
    `      case ComponentType.${c.name}:
        return createDefault${c.className}Properties();`
  ).join('\n');

  // For property factory, it calls the static method directly on class
  const casesGetDefaultPropertiesFactory = components.map(c =>
    `      case ComponentType.${c.name}:
        return ${c.className}Properties.createDefault();`
  ).join('\n');

  const casesGetValidators = components.map(c =>
    `      case ComponentType.${c.name}:
        return ${c.className}Properties.validators;`
  ).join('\n');

  const casesCreateWithProperties = components.map(c =>
    `      case ComponentType.${c.name}:
        return ${c.className}Component(
          id: componentId,
          x: x,
          y: y,
          properties: properties,
        );`
  ).join('\n');

  const utilityMethods = components.map(c =>
    `  static ComponentProperties createDefault${c.className}Properties() {
    return ${c.className}Properties.createDefault();
  }`
  ).join('\n\n');

  const exports = components.map(c => `export '${c.name}/component.dart';`).join('\n');

  // 1. Generate frontend/lib/components/component_factory.dart
  const componentFactoryContent = await readAndFillTemplate(join(templatesDir, 'component_factory.dart.tpl'), {
    IMPORTS: imports,
    COMPONENT_TYPE_ENUM: componentTypeEnum,
    CASES_CREATE_COMPONENT: casesCreateComponent,
    CASES_FROM_JSON: casesFromJson,
    UTILITY_METHODS: utilityMethods,
    CASES_GET_DEFAULT_PROPERTIES: casesGetDefaultProperties,
    CASES_CREATE_WITH_PROPERTIES: casesCreateWithProperties
  });

  // 2. Generate frontend/lib/components/component_properties_factory.dart
  const propertiesFactoryImports = components.map(c => `import '${c.name}/properties.dart';`).join('\n');
  const componentPropertiesFactoryContent = await readAndFillTemplate(join(templatesDir, 'component_properties_factory.dart.tpl'), {
    IMPORTS: propertiesFactoryImports,
    CASES_GET_DEFAULT_PROPERTIES: casesGetDefaultPropertiesFactory,
    CASES_GET_VALIDATORS: casesGetValidators
  });

  // 3. Generate frontend/lib/components/components.dart (Exports)
  const componentsExportContent = await readAndFillTemplate(join(templatesDir, 'components.dart.tpl'), {
    EXPORTS: exports
  });

  const factoryPath = join(rootDir, 'frontend', 'lib', 'components', 'component_factory.dart');
  const propertiesFactoryPath = join(rootDir, 'frontend', 'lib', 'components', 'component_properties_factory.dart');
  const exportsPath = join(rootDir, 'frontend', 'lib', 'components', 'components.dart');

  await fs.writeFile(factoryPath, componentFactoryContent);
  await fs.writeFile(propertiesFactoryPath, componentPropertiesFactoryContent);
  await fs.writeFile(exportsPath, componentsExportContent);
}

export interface CreateComponentOptions {
  name: string;
  className: string;
  properties?: ComponentProperty[];
  componentCode?: string;
  isResizable?: boolean;
}

export async function createComponentFiles(options: CreateComponentOptions) {
  const { name, className, properties = [], componentCode = '', isResizable = true } = options;
  const rootDir = getProjectRoot();
  const componentDir = join(rootDir, 'frontend', 'lib', 'components', name);
  const templatesDir = join(rootDir, 'backend', 'src', 'templates', 'components');

  // Create directory
  await fs.mkdir(componentDir, { recursive: true });

  // Generate Properties Code
  const propertiesCode = properties.map(prop => {
    const displayName = prop.displayName || prop.name;
    switch (prop.type) {
      case 'string':
        return `      const StringProperty(
        key: '${prop.name}',
        displayName: '${displayName}',
        value: '${prop.initialValue}',
        group: '${prop.group ?? 'General'}',
        enable: Enabled(show: true, enabled: true),
      ),`;
      case 'number':
        return `      const NumberProperty(
        key: '${prop.name}',
        displayName: '${displayName}',
        value: ${prop.initialValue},
        min: 0.0,
        max: 1000.0,
        group: '${prop.group ?? 'General'}',
        enable: Enabled(show: true, enabled: true),
      ),`;
      case 'boolean':
        return `      const BooleanProperty(
        key: '${prop.name}',
        displayName: '${displayName}',
        value: ${prop.initialValue},
        group: '${prop.group ?? 'General'}',
        enable: Enabled(show: true, enabled: true),
      ),`;
      case 'color':
        return `      const ComponentColorProperty(
        key: '${prop.name}',
        displayName: '${displayName}',
        value: XDColor(
             ['${prop.initialValue}'],
             type: ColorType.solid,
             stops: [],
             begin: Alignment.topLeft,
             end: Alignment.bottomRight,
         ),
        enable: Enabled(show: true, enabled: true),
        group: '${prop.group ?? 'General'}',
      ),`;
      case 'icon':
        return `      const IconProperty(
            key: '${prop.name}',
            displayName: '${displayName}',
            value: '${prop.initialValue}',
            group: '${prop.group ?? 'General'}',
            enable: Enabled(show: false, enabled: true),
          ),`;
      default:
        return '';
    }
  }).join('\n');

  // Generate Validation Logic
  const validationLogic = `static Map<String, String? Function(dynamic)> get validators => {
${properties.map(prop => {
    switch (prop.type) {
      case 'string':
      case 'icon':
        return `    '${prop.name}': (value) => value is String ? null : '${prop.name} must be a string',`;
      case 'number':
        return `    '${prop.name}': (value) => value is num ? null : '${prop.name} must be a number',`;
      case 'boolean':
        return `    '${prop.name}': (value) => value is bool ? null : '${prop.name} must be a boolean',`;
      case 'color':
        return `    '${prop.name}': (value) {
      if (value is XDColor) return null;
      if (value is String && (value.startsWith('#') || value.startsWith('0x'))) return null;
      if (value is Map && value.containsKey('value')) return null; // JSON structure for color
      return '${prop.name} must be a valid color (Hex string, XDColor, or JSON object)';
    },`;
      default:
        return `    '${prop.name}': (value) => null,`;
    }
  }).join('\n')}
  };`;

  // component.dart content
  let componentContent = componentCode;

  if (!componentContent || componentContent.trim().length === 0) {
    componentContent = await readAndFillTemplate(join(templatesDir, 'component_class.dart.tpl'), {
      CLASS_NAME: className,
      COMPONENT_NAME: name,
      IS_RESIZABLE: isResizable.toString()
    });
  }

  // properties.dart content
  const propertiesContent = await readAndFillTemplate(join(templatesDir, 'component_properties.dart.tpl'), {
    CLASS_NAME: className,
    PROPERTIES_CODE: propertiesCode,
    VALIDATION_LOGIC: validationLogic
  });

  await fs.writeFile(join(componentDir, 'component.dart'), componentContent);
  await fs.writeFile(join(componentDir, 'properties.dart'), propertiesContent);
}

export async function registerComponent(name: string, className: string) {
  // Instead of patching logic, we just regenerate the factories
  await generateComponentFactories();
}
