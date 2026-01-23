
import { config } from 'dotenv';
import { drizzle } from 'drizzle-orm/postgres-js';
import { eq, inArray } from 'drizzle-orm';
import postgres from 'postgres';
import { types } from '../database/schema/types';
import { components } from '../database/schema/components';
import { svgs } from '../database/schema/svgs';
import { ulid } from 'ulidx';
import * as fs from 'fs';
import * as path from 'path';
import { createComponentFiles, generateComponentFactories } from '../backend/src/utils/component_utils';
import { resolveTypePath, generateTypeContent, writeTypeFile } from '../backend/src/utils/type_utils';

// Load environment variables from .env file
config({ path: '.env' });

// Get DATABASE_URL from environment
const DATABASE_URL = process.env['DATABASE_URL'];
if (!DATABASE_URL) {
  throw new Error('DATABASE_URL environment variable is required');
}

async function setupDatabase() {
  console.log('🚀 Starting database seeding...');

  try {
    // Create database connection
    const client = postgres(DATABASE_URL!);
    const db = drizzle(client);

    const typeNames = ['string', 'number', 'boolean', 'color', 'side', 'corner', 'textAlign', 'fontWeight', 'boxFit', 'icon'];
    const componentNames = ['container', 'text', 'image', 'icon'];

    // 1. Cleanup existing defaults and conflicting records
    console.log('🧹 Cleaning up existing default and conflicting records...');

    // Delete explicitly marked defaults
    await db.delete(types).where(eq(types.isDefault, true));
    await db.delete(components).where(eq(components.isDefault, true));
    await db.delete(svgs).where(eq(svgs.isDefault, true));

    // Also delete any existing records that match the names we are about to seed
    // to avoid unique constraint violations
    await db.delete(types).where(inArray(types.name, typeNames));
    await db.delete(components).where(inArray(components.name, componentNames));

    console.log('✅ Cleanup complete.');

    // 2. Seed Types
    console.log('📦 Seeding Types...');
    const defaultTypes = [
      { name: 'string', className: 'String', path: '', structure: 'object', isDefault: true },
      { name: 'number', className: 'Number', path: '', structure: 'object', isDefault: true },
      { name: 'boolean', className: 'Boolean', path: '', structure: 'object', isDefault: true },
      { name: 'color', className: 'Color', path: '', structure: 'object', isDefault: true },
      { name: 'side', className: 'Side', path: '', structure: 'object', isDefault: true },
      { name: 'corner', className: 'Corner', path: '', structure: 'object', isDefault: true },
      { name: 'icon', className: 'Icon', path: '', structure: 'object', isDefault: true },
      {
        name: 'textAlign',
        className: 'TextAlign',
        path: '',
        structure: 'enum',
        enumValues: JSON.stringify(['left', 'right', 'center', 'justify', 'start', 'end']),
        isDefault: true
      },
      {
        name: 'fontWeight',
        className: 'FontWeight',
        path: '',
        structure: 'enum',
        enumValues: JSON.stringify(['w100', 'w200', 'w300', 'normal', 'w500', 'w600', 'bold', 'w800', 'w900']),
        isDefault: true
      },
      {
        name: 'boxFit',
        className: 'BoxFit',
        path: '',
        structure: 'enum',
        enumValues: JSON.stringify(['fill', 'contain', 'cover', 'fitWidth', 'fitHeight', 'none', 'scaleDown']),
        isDefault: true
      },
    ];

    const typesWithIds = [];
    for (const t of defaultTypes) {
      const { absolutePath, relativePath } = resolveTypePath(t.name, t.structure);
      const content = generateTypeContent(t.className, t.structure, t.enumValues ? JSON.parse(t.enumValues) : []);
      await writeTypeFile(absolutePath, content);

      typesWithIds.push({
        id: ulid(),
        ...t,
        path: relativePath
      });
    }

    await db.insert(types).values(typesWithIds);
    console.log(`✅ Loaded and generated ${typesWithIds.length} default types.`);

    // 3. Seed Components
    console.log('🧩 Seeding Components...');

    const getComponentCode = (name: string) => {
      try {
        const filePath = path.join(__dirname, 'components', `${name}.code.txt`);
        return fs.readFileSync(filePath, 'utf8');
      } catch (e) {
        console.warn(`⚠️ Could not read code for component ${name}, defaulting to empty.`);
        return "";
      }
    };

    const defaultComponents = [
      {
        name: 'icon',
        className: 'IconComponent',
        path: 'components/icon',
        isDefault: true,
        isResizable: false, // Handle size via property
        code: getComponentCode('icon'),
        properties: [
          {
            name: 'icon', displayName: 'Icon', type: 'icon', group: 'Icon', initialValue: (() => {
              try { return fs.readFileSync(path.join(__dirname, 'svgs', 'solid', 'house.svg'), 'utf8'); }
              catch { return ""; }
            })()
          },
          { name: 'color', displayName: 'Color', type: 'color', group: 'Appearance', initialValue: '#000000' },
          { name: 'size', displayName: 'Size', type: 'number', group: 'Layout', initialValue: 24.0 },
        ]
      },
      {
        name: 'container',
        className: 'ContainerComponent',
        path: 'components/container',
        isDefault: true,
        isResizable: true,
        code: getComponentCode('container'),
        properties: [
          { name: 'width', displayName: 'Width', type: 'number', group: 'Layout', initialValue: 100.0 },
          { name: 'height', displayName: 'Height', type: 'number', group: 'Layout', initialValue: 100.0 },
          { name: 'backgroundColor', displayName: 'Color', type: 'color', group: 'Appearance', initialValue: '#FFFFFF' },
          { name: 'borderColor', displayName: 'Border Color', type: 'color', group: 'Appearance', initialValue: '#000000' },
          { name: 'borderWidth', displayName: 'Border Width', type: 'number', group: 'Appearance', initialValue: 1.0 },
          { name: 'borderRadius', displayName: 'Radius', type: 'number', group: 'Appearance', initialValue: 0.0 },

          { name: 'shadow', displayName: 'Shadow', type: 'boolean', group: 'Appearance', initialValue: false },
          { name: 'shadowColor', displayName: 'Shadow Color', type: 'color', group: 'Appearance', initialValue: '#33000000' },
          { name: 'shadowBlur', displayName: 'Blur', type: 'number', group: 'Appearance', initialValue: 8.0 },
          { name: 'shadowSpread', displayName: 'Spread', type: 'number', group: 'Appearance', initialValue: 0.0 },
          { name: 'shadowX', displayName: 'X', type: 'number', group: 'Appearance', initialValue: 0.0 },
          { name: 'shadowY', displayName: 'Y', type: 'number', group: 'Appearance', initialValue: 4.0 },
          { name: 'backgroundBlur', displayName: 'Background Blur', type: 'number', group: 'Appearance', initialValue: 0.0 }
        ]
      },
      {
        name: 'text',
        className: 'TextComponent',
        path: 'components/text',
        isDefault: true,
        isResizable: false,
        code: getComponentCode('text'),
        properties: [
          { name: 'content', displayName: 'Content', type: 'string', group: 'Text', initialValue: 'Sample Text' },
          { name: 'fontSize', displayName: 'Font Size', type: 'number', group: 'Text', initialValue: 16.0 },
          { name: 'color', displayName: 'Color', type: 'color', group: 'Text', initialValue: '#000000' },
          { name: 'fontFamily', displayName: 'Font Family', type: 'string', group: 'Text', initialValue: 'Roboto' }
        ]
      },
      {
        name: 'image',
        className: 'ImageComponent',
        path: 'components/image',
        isDefault: true,
        isResizable: true,
        code: getComponentCode('image'),
        properties: [
          { name: 'source', displayName: 'Source', type: 'string', group: 'Image', initialValue: 'https://via.placeholder.com/150' },
          { name: 'width', displayName: 'Width', type: 'number', group: 'Layout', initialValue: 150.0 },
          { name: 'height', displayName: 'Height', type: 'number', group: 'Layout', initialValue: 150.0 },
          { name: 'borderRadius', displayName: 'Radius', type: 'number', group: 'Appearance', initialValue: 0.0 }
        ]
      }
    ];

    const componentsWithIds = [];
    for (const c of defaultComponents) {
      // Generate files
      await createComponentFiles({
        name: c.name,
        className: c.className.replace('Component', ''),
        properties: c.properties as any,
        componentCode: c.code,
        isResizable: c.isResizable
      });

      componentsWithIds.push({
        id: ulid(),
        name: c.name,
        className: c.className,
        path: c.path,
        isDefault: c.isDefault,
        isResizable: c.isResizable,
        code: c.code,
        properties: JSON.stringify(c.properties)
      });
    }

    await db.insert(components).values(componentsWithIds);
    console.log(`✅ Loaded and generated ${componentsWithIds.length} default components.`);

    // 4. Seed SVGs
    console.log('🎨 Seeding SVGs...');
    const svgTypes = ['brands', 'regular', 'solid'];
    const svgsToInsert: any[] = [];

    for (const type of svgTypes) {
      const dirPath = path.join(__dirname, 'svgs', type);
      if (fs.existsSync(dirPath)) {
        const files = fs.readdirSync(dirPath);
        for (const file of files) {
          if (file.endsWith('.svg')) {
            const name = path.parse(file).name;
            const content = fs.readFileSync(path.join(dirPath, file), 'utf8');
            svgsToInsert.push({
              id: ulid(),
              name: name,
              svg: content,
              type: type,
              isDefault: true
            });
          }
        }
      } else {
        console.warn(`⚠️ SVG directory not found: ${dirPath}`);
      }
    }

    if (svgsToInsert.length > 0) {
      const batchSize = 500;
      for (let i = 0; i < svgsToInsert.length; i += batchSize) {
        const batch = svgsToInsert.slice(i, i + batchSize);
        await db.insert(svgs).values(batch);
        console.log(`   Inserted SVG batch ${Math.floor(i / batchSize) + 1} (${batch.length} items)`);
      }
      console.log(`✅ Loaded ${svgsToInsert.length} default SVGs.`);
    } else {
      console.log('ℹ️ No SVGs found to seed.');
    }

    console.log('🏗️ Generating component factories...');
    await generateComponentFactories();
    console.log('✅ Component factories generated.');

    // Close database connection
    await client.end();
    console.log('🎉 Database seeding and file generation completed successfully!');
  } catch (error) {
    console.error('❌ Error seeding database:', error);
    process.exit(1);
  }
}

// Run the script
setupDatabase().then(() => {
  process.exit(0);
}).catch((error) => {
  console.error('Failed to setup database:', error);
  process.exit(1);
});