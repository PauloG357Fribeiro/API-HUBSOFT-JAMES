const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const JavaScriptObfuscator = require('javascript-obfuscator');

const SRC_DIR = path.join(__dirname, 'src');
const DIST_DIR = path.join(__dirname, 'dist');

const OBFUSCATOR_OPTIONS = {
  compact: true,
  controlFlowFlattening: true,
  controlFlowFlatteningThreshold: 0.75,
  stringArray: true,
  stringArrayThreshold: 0.75,
  stringArrayEncoding: ['base64'],
  identifierNamesGenerator: 'hexadecimal',
  numbersToExpressions: true,
  simplify: true,
  splitStrings: true,
  splitStringsChunkLength: 8,
  transformObjectKeys: true,
  selfDefending: true
};

function rmrf(dir) {
  if (fs.existsSync(dir)) {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

function copyDir(src, dest) {
  fs.mkdirSync(dest, { recursive: true });
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);
    if (entry.isDirectory()) {
      copyDir(srcPath, destPath);
    } else {
      fs.copyFileSync(srcPath, destPath);
    }
  }
}

function main() {
  if (!fs.existsSync(SRC_DIR)) {
    console.error(`ERRO: pasta src/ nao encontrada em ${SRC_DIR}`);
    process.exit(1);
  }

  rmrf(DIST_DIR);
  fs.mkdirSync(DIST_DIR, { recursive: true });

  const jsFiles = fs.readdirSync(SRC_DIR).filter((f) => f.endsWith('.js'));
  if (jsFiles.length === 0) {
    console.error('ERRO: nenhum arquivo .js encontrado em src/');
    process.exit(1);
  }

  for (const fileName of jsFiles) {
    const srcPath = path.join(SRC_DIR, fileName);
    const destPath = path.join(DIST_DIR, fileName);
    const code = fs.readFileSync(srcPath, 'utf8');

    console.log(`Ofuscando ${fileName}...`);
    let obfuscated;
    try {
      obfuscated = JavaScriptObfuscator.obfuscate(code, OBFUSCATOR_OPTIONS).getObfuscatedCode();
    } catch (err) {
      console.error(`ERRO ao ofuscar ${fileName}: ${err.message}`);
      process.exit(1);
    }

    fs.writeFileSync(destPath, obfuscated, 'utf8');

    try {
      execFileSync(process.execPath, ['--check', destPath], { stdio: 'pipe' });
    } catch (err) {
      console.error(`ERRO: ${fileName} ofuscado falhou na verificacao de sintaxe (node --check):`);
      console.error(err.stderr ? err.stderr.toString() : err.message);
      process.exit(1);
    }

    console.log(`OK: dist/${fileName}`);
  }

  const manifestSrc = path.join(SRC_DIR, 'manifest.json');
  if (fs.existsSync(manifestSrc)) {
    fs.copyFileSync(manifestSrc, path.join(DIST_DIR, 'manifest.json'));
    console.log('OK: dist/manifest.json (copiado sem ofuscar)');
  } else {
    console.error('ERRO: src/manifest.json nao encontrado');
    process.exit(1);
  }

  const cssSrc = path.join(SRC_DIR, 'content.css');
  if (fs.existsSync(cssSrc)) {
    fs.copyFileSync(cssSrc, path.join(DIST_DIR, 'content.css'));
    console.log('OK: dist/content.css (copiado sem ofuscar)');
  }

  const iconsDir = path.join(SRC_DIR, 'icons');
  if (fs.existsSync(iconsDir)) {
    copyDir(iconsDir, path.join(DIST_DIR, 'icons'));
    console.log('OK: dist/icons/ copiada');
  }

  for (const iconFile of ['icon.png', 'icon.svg']) {
    const iconSrc = path.join(SRC_DIR, iconFile);
    if (fs.existsSync(iconSrc)) {
      fs.copyFileSync(iconSrc, path.join(DIST_DIR, iconFile));
      console.log(`OK: dist/${iconFile} copiado`);
    }
  }

  for (const staticFile of ['atualizador.bat', 'LEIA-ME.txt']) {
    const staticSrc = path.join(SRC_DIR, staticFile);
    if (fs.existsSync(staticSrc)) {
      fs.copyFileSync(staticSrc, path.join(DIST_DIR, staticFile));
      console.log(`OK: dist/${staticFile} copiado`);
    }
  }

  console.log('\nBuild concluido com sucesso.');
}

main();
