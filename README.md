# NEXUS-CARGO
    🦀 Nexus Cargo v1.0: The Zero-Delta build tool. Inspired by cargo, but 100% local and dependency-free. Compiles Rust, generates a SHA-256 proof for every build, and guarantees reproducibility. One binary, one script, absolute sovereignty. No cloud, no registry.
<div align="center">
  <h1>🦀 NEXUS CARGO v1.0</h1>
  <p><strong>Le build run Zéro-Delta. Ton cargo personnel, 100% local, 100% souverain.</strong></p>
  
  [![Rust](https://img.shields.io/badge/Core-Rust-000000?style=for-the-badge&logo=rust&logoColor=white)](#)
  [![Zero-Delta](https://img.shields.io/badge/Hash-SHA--256-00ff9d?style=for-the-badge)](#)
  [![Local-First](https://img.shields.io/badge/Local--First-100%25-blue?style=for-the-badge)](#)
  [![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](#)
</div>

---

## 🧬 Overview

**Nexus Cargo** (`nxc`) n'est pas un simple script de build. C'est un **outil de gestion de projet Rust** inspiré de `cargo`, mais avec une promesse unique : la **Zéro-Delta**.

**La règle de Nexus Cargo :** *Même source + même compilateur = même hash SHA-256. Partout dans le monde. Pas de cloud, pas de registre, pas de dépendance.*

- **Zéro dépendance** : SHA-256 embarqué en pur Rust.
- **Zéro cloud** : 100% local, aucun appel réseau.
- **Zéro fioriture** : Un seul binaire, des commandes simples, des résultats prouvés.

---

## ⚙️ Les Commandes (La Puissance)

| Commande | Ce qu'elle fait |
| :--- | :--- |
| `nxc new <dossier>` | Crée un projet prêt à l'emploi (`NXC.toml` + `src/`). |
| `nxc build <dossier>` | Compile `src/main.rs` → `target/<nom>` + hash SHA-256. |
| `nxc run <dossier> [args]` | Build puis exécute le programme. |
| `nxc test <dossier>` | Compile et exécute `src/tests.rs`. |
| `nxc hash <dossier>` | Affiche le hash SHA-256 du binaire (la preuve Zéro-Delta). |
| `nxc clean <dossier>` | Supprime le dossier `target/`. |
| `nxc version` | Affiche la version. |
| `nxc aide` | Affiche l'aide. |

---

## 🚀 Installation & Utilisation

### Prérequis
- `rustc` (Rust compiler).

### Installation Rapide
```bash
# Clone le dépôt
git clone https://github.com/Aissamohammedi88/nexus-cargo.git
cd nexus-cargo
nxc new mon-projet
nxc build mon-projet
nxc run mon-projet
nxc test mon-projet
nxc hash mon-projet   # La preuve Zéro-Delta
🛡️ La Promesse Zéro-Delta (Preuves)

Ce projet n'est pas une démo marketing. C'est un outil de production.
Preuve	Résultat
Zéro-Delta vérifié	2 builds → même hash SHA-256
Compilation	✅ Succès (cargo ou rustc seul)
Démo complète	✅ new → build → run → test → hash
SHA-256 natif	✅ Implémenté en pur Rust, zéro dépendance

Le script de déploiement fait tout :

    Vérifie les outils (cargo ou rustc).

    Écrit les sources (main.rs, builder.rs, manifest.rs, sha256.rs).

    Compile le binaire nxc.

    Teste la Zéro-Delta (2 builds → même hash).

    Prépare le dépôt git pour la publication mondiale.

📦 Architecture du Dépôt
text

nexus-cargo/
├── nexus-cargo-deploy.sh   # Le script tout-en-un
├── Cargo.toml              # Manifeste Rust
├── README.md               # Ce fichier
├── LICENSE                 # MIT
├── .gitignore
└── src/
    ├── main.rs             # CLI (commandes)
    ├── builder.rs          # Moteur de build
    ├── manifest.rs         # Parseur NXC.toml
    └── sha256.rs           # SHA-256 pur Rust (Zéro-Delta)

🧬 Signé

Aissa Mohammedi (DGK)
Fondateur de Nexus Quantum — Architecte Systémique
"We don't just build code. We prove it."

# Lance le script de déploiement (compile tout, teste, prépare git)
bash nexus-cargo-deploy.sh
