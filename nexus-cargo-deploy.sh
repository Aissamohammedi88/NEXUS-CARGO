#!/usr/bin/env bash
# ============================================================
#  NEXUS CARGO v1.0 — « build run » auto-suffisant (Senior Protocol)
#
#  Inspiré de tes anciens déplois (nexus-deploy.sh) : UN SEUL script
#  qui écrit les sources, compile, déroule les phases, et prépare la
#  publication MONDIALE GitHub — ton propre outil à la
#  https://github.com/rust-lang/cargo : la commande `nxc`.
#
#  Ça se LANCE :      bash nexus-cargo-deploy.sh
#  Ça crée :          ~/nexus-cargo  (projet complet, prêt à pousser)
#  La promesse :      aucun exec, aucun kill — la fenêtre ne se ferme
#                     jamais toute seule (leçon des 12 tentatives).
#  La retouche :      Zéro-Delta (SHA-256 embarqué en pur Rust,
#                     zéro dépendance, 100 % local, docs FR/EN).
# ============================================================
set -u

NXC_HOME="${NXC_HOME:-$HOME/nexus-cargo}"
NXC_RUSTC_SEUL=0

hr() { printf '%s\n' "======================================================================"; }

echo "$(hr)
  NEXUS CARGO v1.0 — build run auto-suffisant (Senior Protocol)
  Ton cargo à toi : nxc build / run / test / hash — Zéro-Delta mondial
$(hr)"
echo "  Mode    : script sans TUI"
echo "  Projet  : $NXC_HOME"

# ============================================================
# [1/5] OUTILS — vérification honnête
# ============================================================
hr; echo "[1/5] OUTILS"
CARGO_V="$(command -v cargo >/dev/null 2>&1 && cargo --version 2>/dev/null || true)"
if [ -n "$CARGO_V" ]; then
    echo "[OK] cargo : $CARGO_V"
else
    RUSTC_V="$(command -v rustc >/dev/null 2>&1 && rustc --version 2>/dev/null || true)"
    if [ -n "$RUSTC_V" ]; then
        echo "[OK] rustc seul : $RUSTC_V (cargo absent — je compile par rustc)"
        NXC_RUSTC_SEUL=1
    else
        echo "[ABANDON] ni cargo ni rustc fonctionnels — installe Rust puis relance :"
        echo "  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o /tmp/rustup.sh && bash /tmp/rustup.sh"
        exit 1
    fi
fi
GIT_PRET=0
if command -v git >/dev/null 2>&1; then GIT_PRET=1; echo "[OK] git : $(git --version)"; else echo "[!] git absent — publication GitHub à faire plus tard"; fi

# ============================================================
# [2/5] SOURCES — les modules embarqués, comme les anciens déplois
# ============================================================
hr; echo "[2/5] SOURCES — écriture des modules embarqués"
mkdir -p "$NXC_HOME/src"

cat > "$NXC_HOME/Cargo.toml" <<'TOML_EOF'
[package]
name = "nexus-cargo"
version = "1.0.0"
edition = "2021"
description = "nxc — le build run Zéro-Delta : ton cargo personnel, 100 % local"
license = "MIT"

[[bin]]
name = "nxc"
path = "src/main.rs"

[profile.release]
opt-level = 3
TOML_EOF
echo "  [OK] Cargo.toml"

cat > "$NXC_HOME/src/main.rs" <<'MAIN_EOF'
//! NEXUS CARGO — `nxc` : ton outil de build personnel, à la rust-lang/cargo.
//! Zéro dépendance, Zéro-Delta (SHA-256 embarqué), 100 % local.

mod builder;
mod manifest;
mod sha256;

use std::env;
use std::path::Path;
use std::process::exit;

const VERSION: &str = "1.0.0";

const AIDE: &str = "nxc — NEXUS CARGO v1.0.0 : le build run Zéro-Delta, 100 % local.

UTILISATION
  nxc new <dossier>        crée un projet prêt à l'emploi (NXC.toml + src/)
  nxc build <dossier>      compile src/main.rs -> target/<nom> + hash SHA-256
  nxc run <dossier> [args] build puis exécute le programme
  nxc test <dossier>       compile et exécute src/tests.rs
  nxc hash <dossier>       hash SHA-256 du binaire (preuve Zéro-Delta)
  nxc clean <dossier>      supprime target/
  nxc version              version
  nxc aide                 cette aide

LA RETOUCHE MONDIALE
  - Zéro-Delta    : même source + même rustc -> même hash SHA-256, partout.
  - Zéro dépendance : un seul binaire, SHA-256 embarqué en pur Rust.
  - 100 % local   : aucune connexion, aucun registre, aucun réseau.
";

fn main() {
    let args: Vec<String> = env::args().skip(1).collect();
    if args.is_empty() {
        print!("{}", AIDE);
        exit(0);
    }
    let cmd = args[0].clone();
    let reste: Vec<String> = args[1..].to_vec();
    let code = match cmd.as_str() {
        "new" => cmd_new(&reste),
        "build" => cmd_build(&reste),
        "run" => cmd_run(&reste),
        "test" => cmd_test(&reste),
        "hash" => cmd_hash(&reste),
        "clean" => cmd_clean(&reste),
        "version" | "--version" | "-V" => {
            println!("nxc v{} — NEXUS CARGO « Zéro-Delta »", VERSION);
            0
        }
        "aide" | "--help" | "-h" => {
            print!("{}", AIDE);
            0
        }
        autre => {
            eprintln!("nxc : commande inconnue « {} » — tape : nxc aide", autre);
            2
        }
    };
    exit(code);
}

fn cmd_new(args: &[String]) -> i32 {
    match args.first() {
        Some(dest) => match builder::new_projet(Path::new(dest)) {
            Ok(()) => 0,
            Err(e) => { eprintln!("nxc : {}", e); 1 }
        },
        None => { eprintln!("nxc : usage : nxc new <dossier>"); 2 }
    }
}

fn cmd_build(args: &[String]) -> i32 {
    match builder::Projet::depuis_args(args).and_then(|p| p.build()) {
        Ok((bin, hash)) => {
            println!("✓ build : {}", bin.display());
            println!("  Zéro-Delta : {}", hash);
            0
        }
        Err(e) => { eprintln!("nxc : {}", e); 1 }
    }
}

fn cmd_run(args: &[String]) -> i32 {
    match builder::Projet::depuis_args(args) {
        Ok(p) => match p.run(&args[1..]) {
            Ok(c) => c,
            Err(e) => { eprintln!("nxc : {}", e); 1 }
        },
        Err(e) => { eprintln!("nxc : {}", e); 1 }
    }
}

fn cmd_test(args: &[String]) -> i32 {
    match builder::Projet::depuis_args(args).and_then(|p| p.test()) {
        Ok(()) => { println!("✓ tests : tous passés"); 0 }
        Err(e) => { eprintln!("nxc : {}", e); 1 }
    }
}

fn cmd_hash(args: &[String]) -> i32 {
    match builder::Projet::depuis_args(args).and_then(|p| p.hash()) {
        Ok(h) => { println!("{}", h); 0 }
        Err(e) => { eprintln!("nxc : {}", e); 1 }
    }
}

fn cmd_clean(args: &[String]) -> i32 {
    match builder::Projet::depuis_args(args).and_then(|p| p.clean()) {
        Ok(()) => { println!("✓ target/ supprimé"); 0 }
        Err(e) => { eprintln!("nxc : {}", e); 1 }
    }
}
MAIN_EOF
echo "  [OK] src/main.rs"

cat > "$NXC_HOME/src/manifest.rs" <<'MANIFEST_EOF'
//! Lecteur de NXC.toml — zéro dépendance, en français.

#[allow(dead_code)]
pub struct Manifest {
    pub name: String,
    pub version: String,
    pub authors: String,
}

impl Manifest {
    pub fn parse(path: &std::path::Path) -> Result<Manifest, String> {
        let texte = std::fs::read_to_string(path)
            .map_err(|_| format!("manifeste introuvable : {}", path.display()))?;
        let mut name = String::new();
        let mut version = String::new();
        let mut authors = String::new();
        for ligne in texte.lines() {
            let ligne = ligne.trim();
            if ligne.starts_with('[') || ligne.starts_with('#') || ligne.is_empty() {
                continue;
            }
            let (cle, val) = match ligne.split_once('=') {
                Some((k, v)) => (k.trim(), v.trim()),
                None => continue,
            };
            let val = val.trim_matches('"').trim_matches('\'');
            match cle {
                "name" => name = val.to_string(),
                "version" => version = val.to_string(),
                "authors" => authors = val.to_string(),
                _ => {}
            }
        }
        if name.is_empty() {
            return Err("NXC.toml : champ `name` manquant dans [package]".to_string());
        }
        if version.is_empty() {
            version = "0.1.0".to_string();
        }
        Ok(Manifest { name, version, authors })
    }
}
MANIFEST_EOF
echo "  [OK] src/manifest.rs"

cat > "$NXC_HOME/src/builder.rs" <<'BUILDER_EOF'
//! Le moteur : new / build / run / test / hash / clean — Zéro-Delta.

use crate::manifest::Manifest;
use crate::sha256::sha256_hex;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

pub struct Projet {
    pub dir: PathBuf,
}

const MODELE_MAIN: &str = r#"// Ton premier projet nxc — Zéro-Delta, hashé SHA-256.
fn main() {
    let qui = std::env::args().nth(1).unwrap_or_else(|| "monde".to_string());
    println!("Bonjour {} ! — compilé par nxc, déterministe, 100 % local.", qui);
}
"#;

const MODELE_TESTS: &str = r#"// Tests de ton projet — lance : nxc test
fn additionne(a: i32, b: i32) -> i32 {
    a + b
}

#[test]
fn positifs() {
    assert_eq!(additionne(2, 3), 5);
}

#[test]
fn negatifs() {
    assert_eq!(additionne(-2, -3), -5);
}
"#;

pub fn new_projet(dest: &Path) -> Result<(), String> {
    let main_rs = dest.join("src/main.rs");
    if main_rs.exists() {
        return Err(format!("projet déjà existant : {}", dest.display()));
    }
    fs::create_dir_all(dest.join("src")).map_err(|e| format!("création dossier : {}", e))?;
    let nom = dest
        .file_name()
        .map(|n| n.to_string_lossy().to_string())
        .unwrap_or_else(|| "mon-projet".to_string());
    let toml = format!(
        "[package]\nname = \"{}\"\nversion = \"0.1.0\"\nauthors = [\"toi\"]\n",
        nom
    );
    fs::write(dest.join("NXC.toml"), toml).map_err(|e| e.to_string())?;
    fs::write(&main_rs, MODELE_MAIN).map_err(|e| e.to_string())?;
    fs::write(dest.join("src/tests.rs"), MODELE_TESTS).map_err(|e| e.to_string())?;
    fs::write(dest.join(".gitignore"), "/target\n").map_err(|e| e.to_string())?;
    println!("✓ projet créé : {}", dest.display());
    println!(
        "  suite : nxc build {}   puis   nxc run {}",
        dest.display(),
        dest.display()
    );
    Ok(())
}

impl Projet {
    pub fn depuis_args(args: &[String]) -> Result<Projet, String> {
        let dir = match args.first() {
            Some(d) => PathBuf::from(d),
            None => PathBuf::from("."),
        };
        if !dir.join("NXC.toml").is_file() {
            return Err(format!(
                "pas de NXC.toml dans « {} » — commence par : nxc new {}",
                dir.display(),
                dir.display()
            ));
        }
        Ok(Projet { dir })
    }

    pub fn lire_manifest(&self) -> Result<Manifest, String> {
        Manifest::parse(&self.dir.join("NXC.toml"))
    }

    fn target(&self) -> PathBuf {
        self.dir.join("target")
    }

    /// Compile src/main.rs -> target/<nom>. Renvoie (binaire, hash SHA-256).
    pub fn build(&self) -> Result<(PathBuf, String), String> {
        let m = self.lire_manifest()?;
        fs::create_dir_all(self.target()).map_err(|e| e.to_string())?;
        let out = self.target().join(&m.name);
        let st = Command::new("rustc")
            .arg("-O")
            .arg(self.dir.join("src/main.rs"))
            .arg("-o")
            .arg(&out)
            .status()
            .map_err(|_| "rustc introuvable — installe Rust (https://rustup.rs)".to_string())?;
        if !st.success() {
            return Err("compilation échouée — corrige les erreurs ci-dessus".to_string());
        }
        let octets = fs::read(&out).map_err(|e| e.to_string())?;
        let hash = sha256_hex(&octets);
        fs::write(self.target().join("nxc.hash"), &hash).map_err(|e| e.to_string())?;
        Ok((out, hash))
    }

    pub fn run(&self, args: &[String]) -> Result<i32, String> {
        let (bin, _) = self.build()?;
        let st = Command::new(bin)
            .args(args)
            .status()
            .map_err(|e| e.to_string())?;
        Ok(st.code().unwrap_or(-1))
    }

    pub fn test(&self) -> Result<(), String> {
        let src = self.dir.join("src/tests.rs");
        if !src.is_file() {
            return Err("pas de src/tests.rs — rien à tester".to_string());
        }
        fs::create_dir_all(self.target()).map_err(|e| e.to_string())?;
        let out = self.target().join("nxc-tests");
        let st = Command::new("rustc")
            .arg("--test")
            .arg("-O")
            .arg(&src)
            .arg("-o")
            .arg(&out)
            .status()
            .map_err(|_| "rustc introuvable".to_string())?;
        if !st.success() {
            return Err("compilation des tests échouée".to_string());
        }
        let st = Command::new(out).status().map_err(|e| e.to_string())?;
        if !st.success() {
            return Err("des tests ont échoué — regarde ci-dessus".to_string());
        }
        Ok(())
    }

    /// Hash du dernier build (rebuild si besoin) — la preuve Zéro-Delta.
    pub fn hash(&self) -> Result<String, String> {
        let fichier = self.target().join("nxc.hash");
        if let Ok(h) = fs::read_to_string(&fichier) {
            let h = h.trim().to_string();
            if !h.is_empty() {
                return Ok(h);
            }
        }
        self.build().map(|(_, h)| h)
    }

    pub fn clean(&self) -> Result<(), String> {
        let t = self.target();
        if t.exists() {
            fs::remove_dir_all(t).map_err(|e| e.to_string())?;
        }
        Ok(())
    }
}
BUILDER_EOF
echo "  [OK] src/builder.rs"

cat > "$NXC_HOME/src/sha256.rs" <<'SHA_EOF'
//! SHA-256 pur Rust (FIPS 180-4) — la preuve Zéro-Delta embarquée,
//! zéro dépendance : ça tourne pareil partout dans le monde.

const K: [u32; 64] = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1,
    0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
    0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
    0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
    0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
    0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
];

pub fn sha256_hex(data: &[u8]) -> String {
    let mut h: [u32; 8] = [
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
    ];
    let bitlen = (data.len() as u64).wrapping_mul(8);
    let mut msg = data.to_vec();
    msg.push(0x80);
    while msg.len() % 64 != 56 {
        msg.push(0);
    }
    msg.extend_from_slice(&bitlen.to_be_bytes());

    for chunk in msg.chunks(64) {
        let mut w = [0u32; 64];
        for i in 0..16 {
            w[i] = u32::from_be_bytes([
                chunk[4 * i],
                chunk[4 * i + 1],
                chunk[4 * i + 2],
                chunk[4 * i + 3],
            ]);
        }
        for i in 16..64 {
            let s0 = w[i - 15].rotate_right(7) ^ w[i - 15].rotate_right(18) ^ (w[i - 15] >> 3);
            let s1 = w[i - 2].rotate_right(17) ^ w[i - 2].rotate_right(19) ^ (w[i - 2] >> 10);
            w[i] = w[i - 16]
                .wrapping_add(s0)
                .wrapping_add(w[i - 7])
                .wrapping_add(s1);
        }
        let (mut a, mut b, mut c, mut d, mut e, mut f, mut g, mut hh) =
            (h[0], h[1], h[2], h[3], h[4], h[5], h[6], h[7]);
        for i in 0..64 {
            let s1 = e.rotate_right(6) ^ e.rotate_right(11) ^ e.rotate_right(25);
            let ch = (e & f) ^ ((!e) & g);
            let t1 = hh
                .wrapping_add(s1)
                .wrapping_add(ch)
                .wrapping_add(K[i])
                .wrapping_add(w[i]);
            let s0 = a.rotate_right(2) ^ a.rotate_right(13) ^ a.rotate_right(22);
            let maj = (a & b) ^ (a & c) ^ (b & c);
            let t2 = s0.wrapping_add(maj);
            hh = g;
            g = f;
            f = e;
            e = d.wrapping_add(t1);
            d = c;
            c = b;
            b = a;
            a = t1.wrapping_add(t2);
        }
        h[0] = h[0].wrapping_add(a);
        h[1] = h[1].wrapping_add(b);
        h[2] = h[2].wrapping_add(c);
        h[3] = h[3].wrapping_add(d);
        h[4] = h[4].wrapping_add(e);
        h[5] = h[5].wrapping_add(f);
        h[6] = h[6].wrapping_add(g);
        h[7] = h[7].wrapping_add(hh);
    }
    h.iter().map(|x| format!("{:08x}", x)).collect()
}
SHA_EOF
echo "  [OK] src/sha256.rs"

cat > "$NXC_HOME/README.md" <<'README_EOF'
# NEXUS CARGO — `nxc`

**FR** — Ton propre outil de build, à la [rust-lang/cargo](https://github.com/rust-lang/cargo),
avec ta retouche mondiale : **Zéro-Delta** — le hash SHA-256 de ton build est
embarqué en pur Rust, sans dépendance. Un seul binaire, 100 % local, 100 % français.

**EN** — Your own build tool, in the spirit of [rust-lang/cargo](https://github.com/rust-lang/cargo),
with a worldwide touch: **Zero-Delta** — SHA-256 build hashing built-in, in pure Rust,
zero dependencies. One small binary, 100 % local, French-first.

## Build & Run

```bash
cargo build --release          # ou : bash nexus-cargo-deploy.sh (tout-en-un)
./target/release/nxc new mon-projet
./target/release/nxc build mon-projet
./target/release/nxc run mon-projet
./target/release/nxc test mon-projet
./target/release/nxc hash mon-projet   # la preuve Zéro-Delta
```

## Les commandes / The commands

| Commande | Français | English |
|---|---|---|
| `nxc new`   | crée un projet         | scaffold a project |
| `nxc build` | compile + hash SHA-256 | compile + SHA-256 hash |
| `nxc run`   | build puis exécute     | build then run |
| `nxc test`  | exécute les tests      | run the tests |
| `nxc clean` | supprime target/       | remove target/ |

## Zéro-Delta / Zero-Delta

Même source + même rustc ⇒ même hash SHA-256, partout dans le monde.
Same source + same rustc ⇒ same SHA-256 hash, anywhere on Earth.

## Licence / License

MIT — voir [LICENSE](LICENSE).
README_EOF
echo "  [OK] README.md (FR/EN — mondial)"

cat > "$NXC_HOME/LICENSE" <<'LICENSE_EOF'
MIT License

Copyright (c) 2026 NEXUS Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
LICENSE_EOF
echo "  [OK] LICENSE (MIT)"

cat > "$NXC_HOME/.gitignore" <<'GITIGNORE_EOF'
/target
/demo-hello/target
GITIGNORE_EOF
echo "  [OK] .gitignore"

# ============================================================
# [3/5] COMPILATION — release
# ============================================================
hr; echo "[3/5] COMPILATION (release)"
if [ "$NXC_RUSTC_SEUL" = "0" ]; then
    (cd "$NXC_HOME" && cargo build --release --quiet) \
        || { echo "[ABANDON] cargo build a échoué"; exit 1; }
else
    mkdir -p "$NXC_HOME/target/release"
    (cd "$NXC_HOME" && rustc -O src/main.rs -o target/release/nxc) \
        || { echo "[ABANDON] rustc a échoué"; exit 1; }
fi
BIN="$NXC_HOME/target/release/nxc"
echo "[OK] Binaire prêt : $(wc -c < "$BIN") octets — $BIN"

# ============================================================
# [4/5] DÉMO + ZÉRO-DELTA — new, build, run, test, hash ×2
# ============================================================
hr; echo "[4/5] DÉMO ZÉRO-DELTA"
DEMO="$NXC_HOME/demo-hello"
rm -rf "$DEMO"
"$BIN" new "$DEMO"   || { echo "[ABANDON] nxc new"; exit 1; }
"$BIN" build "$DEMO" || { echo "[ABANDON] nxc build"; exit 1; }
echo "── nxc run ──"
"$BIN" run "$DEMO" NEXUS || { echo "[ABANDON] nxc run"; exit 1; }
echo "── nxc test ──"
"$BIN" test "$DEMO" || { echo "[ABANDON] nxc test"; exit 1; }
H1="$("$BIN" hash "$DEMO")"
"$BIN" build "$DEMO" >/dev/null || { echo "[ABANDON] 2e build"; exit 1; }
H2="$("$BIN" hash "$DEMO")"
if [ -n "$H1" ] && [ "$H1" = "$H2" ]; then
    echo "[OK] ZÉRO-DELTA vérifié : 2 builds → même hash SHA-256"
    echo "     $H1"
else
    echo "[!] ZÉRO-DELTA : hash différents ($H1 / $H2) — rustc non déterministe ici"
fi
# installation globale (petit plus : nxc marche partout)
if mkdir -p "$HOME/.local/bin" 2>/dev/null && ln -sf "$BIN" "$HOME/.local/bin/nxc" 2>/dev/null; then
    echo "[OK] commande globale : nxc (~/.local/bin/nxc)"
fi

# ============================================================
# [5/5] PUBLICATION MONDIALE — git prêt, push à toi
# ============================================================
hr; echo "[5/5] PUBLICATION MONDIALE (GitHub)"
if [ "$GIT_PRET" = "1" ]; then
    if [ ! -d "$NXC_HOME/.git" ]; then
        git -C "$NXC_HOME" init -q -b main 2>/dev/null || git -C "$NXC_HOME" init -q
    fi
    git -C "$NXC_HOME" add -A
    git -C "$NXC_HOME" -c user.name="${GIT_AUTHOR_NAME:-nexus}" \
        -c user.email="${GIT_AUTHOR_EMAIL:-nexus@local}" \
        commit -q -m "nexus-cargo v1.0.0 — nxc : build run Zéro-Delta (FR/EN)" 2>/dev/null || true
    echo "[OK] dépôt git local prêt avec un commit initial"
else
    echo "[!] git absent — la publication se fera une fois git installé"
fi

cat <<'PUB_EOF'

── PUBLIE TON OUTIL AU MONDE ENTIER ──────────────────────────
 1. Crée le dépôt VIDE  https://github.com/<TON-COMPTE>/nexus-cargo
 2. Puis copie-colle :
      cd ~/nexus-cargo
      git remote add origin https://github.com/<TON-COMPTE>/nexus-cargo.git
      git push -u origin main
 3. Le monde entier pourra alors faire :
      git clone https://github.com/<TON-COMPTE>/nexus-cargo
      cd nexus-cargo && cargo run -- aide
PUB_EOF

hr
echo "[OK] Deploiement termine, Commandant."
echo "     nxc aide          — les commandes"
echo "     nxc new mon-projet — commence ton premier projet"
exit 0
