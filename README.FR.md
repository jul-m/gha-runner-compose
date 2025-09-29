
# gha-runner-compose

> Exécutez vos workflows GitHub Actions dans des conteneurs reproduisant fidèlement les runners hébergés par GitHub.

> [ English Version - Version Anglaise](./README.md)

Ce projet fournit des images Docker et les outils nécessaires pour créer et lancer des runners GitHub Actions auto-hébergés dans un environnement équivalent aux runners Ubuntu fournis par GitHub. L'utilisation de Docker offre une solution rapide et flexible pour héberger vos runners, que ce soit pour bénéficier de ressources plus puissantes, contourner certaines limitations des runners standards, ou exécuter des workflows ARM64 sur des dépôts privés. Ce projet est également conçu pour servir de base aux tests locaux de workflows GitHub Actions avec des outils comme [act](https://github.com/nektos/act), en garantissant un environnement de test aussi proche que possible de celui des runners officiels.

Sous le capot, ce projet s’appuie sur les mêmes scripts que ceux utilisés par `actions/runner-images` pour installer les composants logiciels. Vous pouvez soit utiliser une image pré-construite, soit générer vos propres images en sélectionnant précisément les composants à inclure afin d’optimiser la taille finale.

> [!WARNING]
> Ce projet est en cours de développement actif. Certaines fonctionnalités peuvent être instables et des changements majeurs sont à prévoir. Les images générées sont actuellement destinées à des fins de test et de développement.

---

## Sommaire
- [gha-runner-compose](#gha-runner-compose)
  - [Sommaire](#sommaire)
  - [Démarrage rapide](#démarrage-rapide)
    - [Choisir ou construire une image](#choisir-ou-construire-une-image)
    - [Déployer un runner GitHub auto-hébergé](#déployer-un-runner-github-auto-hébergé)
    - [Tester localement vos workflows](#tester-localement-vos-workflows)
  - [Générer des images personnalisées (sans Docker Compose)](#générer-des-images-personnalisées-sans-docker-compose)
    - [Cas général](#cas-général)
    - [Image de base](#image-de-base)
    - [Build avancé](#build-avancé)
  - [Fonctionnement du build](#fonctionnement-du-build)
  - [Entrypoint](#entrypoint)
  - [Structure du dépôt](#structure-du-dépôt)
  - [Licence](#licence)
  - [Avertissement — Absence de garantie et limitation de responsabilité](#avertissement--absence-de-garantie-et-limitation-de-responsabilité)

---

## Démarrage rapide
### Choisir ou construire une image

Les images des runners GitHub officiels sont construites à partir d'un ensemble de scripts, chacun installant un composant spécifique. Ce projet propose une image contenant l'ensemble des composants (`<image-tag>`), mais celle-ci est volumineuse. Le système de build Docker mis en œuvre ici permet de créer des images personnalisées contenant uniquement les composants nécessaires, afin d'optimiser leur taille. La liste des composants disponibles est fournie dans [docs/components.md](./docs/components.md). Des images pré-construites regroupant des ensembles de composants sont également proposées (voir [docs/images.md](./docs/images.md)).

Trois scénarios sont possibles :

1. **Utiliser une image pré-construite telle quelle :**
    - Aucun build n'est nécessaire, le démarrage est immédiat.
    - *Exemple :* dans `compose.yml`, mettez à jour la ligne `image: ghcr.io/jul-m/gha-runner-compose:u24.04-essentials-latest` avec l'image désirée.
2. **Étendre une image pré-construite :**
    - Idéal si une image existante vous convient presque, mais qu'il manque quelques outils. Vous pouvez ajouter uniquement les composants manquants au lieu de tout reconstruire.
    - *Exemple :* dans `compose.build.yml`, mettez à jour les arguments de build :
        - `BASE_IMAGE` : image de base à étendre (ex. `ghcr.io/jul-m/gha-runner-compose:u24.04-essentials-latest`).
        - `RUNNER_COMPONENTS` : liste des composants à ajouter. Les composants déjà présents dans l'image de base seront ignorés.
3. **Construire une image depuis zéro :**
    - Recommandé si aucune image pré-construite ne correspond à vos besoins ou si vous souhaitez optimiser au maximum la taille de l'image.
    - Vous pouvez :
        - Partir de l'image `ghcr.io/jul-m/gha-runner-compose-base:u24.04-latest`, qui contient uniquement les prérequis (`BASE_IMAGE=ghcr.io/jul-m/gha-runner-compose-base:u24.04-latest`).
        - Construire depuis une image Ubuntu 24.04 officielle en retirant l'argument `BASE_IMAGE` (ou en le définissant sur `base`).
    - Listez ensuite l'ensemble des composants souhaités dans `RUNNER_COMPONENTS` (ex. `RUNNER_COMPONENTS=yq,docker,java-tools`).

Pour construire une image personnalisée, vous pouvez utiliser :
- **Docker Compose** avec le fichier [compose.build.yml](./compose.build.yml) (voir la section suivante).
- La commande **`docker buildx build`** (voir la section [Générer des images personnalisées](#générer-des-images-personnalisées-sans-docker-compose)).

La liste complète des composants et catégories est disponible dans [docs/components.md](./docs/components.md). Il est possible d'installer une catégorie entière en spécifiant `all-<category>`. Notez que certains composants ne sont pas disponibles sur l'architecture ARM64.

### Déployer un runner GitHub auto-hébergé

Si vous n'avez jamais utilisé de runners GitHub auto-hébergés, consultez la [documentation officielle de GitHub](https://docs.github.com/fr/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners) avant de commencer.

1. **Clonez ce dépôt :**
    ```bash
    git clone https://github.com/jul-m/gha-runner-compose.git
    cd gha-runner-compose
    ```
2. **Générez un token d’enregistrement :**
    - Rendez-vous dans les paramètres du dépôt ou de l'organisation cible : `Settings` > `Actions` > `Runners` > `New self-hosted runner`.
    - Copiez la valeur de l'argument `--token` affichée dans la commande de configuration.
    - **Note:** Ce token a une durée de vie limitée (environ une heure).

3. **Configurez votre environnement :**
    - Copiez le modèle [.env.example](./.env.example) vers un fichier `.env`.
    - Éditez les valeurs nécessaires :
        - `RUNNER_REPO_URL` : URL de la cible — dépôt (`https://github.com/<owner>/<repo>`) ou organisation (`https://github.com/<org>`).
        - `RUNNER_TOKEN` : Token d’enregistrement généré à l'étape précédente.
        - `RUNNER_LABELS` (optionnel) : Étiquettes personnalisées, séparées par des virgules.

4. **Préparez votre fichier Docker Compose :**
    - Choisissez entre `compose.yml` (image pré-construite) et `compose.build.yml` (build personnalisé).
    - **Si vous utilisez `compose.yml` (image existante) :**
        - Modifiez la directive `image` pour spécifier l'image souhaitée.
    - **Si vous utilisez `compose.build.yml` (build personnalisé) :**
        - Pour étendre une image :
            - `build.args.BASE_IMAGE` : Image de base à étendre.
            - `build.args.RUNNER_COMPONENTS` : Liste des composants à ajouter.
        - Pour construire depuis zéro :
            - Supprimez ou commentez la ligne `BASE_IMAGE`.
            - `build.args.RUNNER_COMPONENTS` : Liste complète des composants à inclure.
    - **Dans tous les cas :**
        - `env_file` : Assurez-vous qu'il référence votre fichier `.env`.
        - `environment.RUNNER_NAME` : Nom unique pour votre runner.
        - `privileged: true` : **À n'activer que si vos workflows nécessitent Docker (Docker-in-Docker)**. Le composant `docker` doit être inclus dans l'image.
          > [!WARNING]
          > L'activation de ce mode a des implications de sécurité importantes. Ne l'utilisez que si vous en comprenez les risques.
        - **Volume `/opt/actions-runner` :**
            - Ce volume assure la persistance de la configuration du runner. Le token d'enregistrement n'est utilisé qu'au premier démarrage.
            - Si vous détruisez le volume, vous devrez générer un nouveau token pour ré-enregistrer le runner.
            - **Utilisez un volume distinct pour chaque instance de runner.**

5. **Lancez le ou les conteneurs :**
    ```bash
    # Pour un build personnalisé
    docker compose -f compose.build.yml up -d --build

    # Pour une image pré-construite
    docker compose -f compose.yml up -d
    ```
    Le temps de construction dépend du nombre de composants à installer et de la vitesse de votre connexion.

6. **Vérifiez le statut du runner :**
    - **Logs du conteneur :**
      ```shell
      # Authentication
      √ Connected to GitHub
      # Runner Registration
      √ Runner successfully added
      √ Runner connection is good
      # Runner settings
      √ Settings Saved.
      [entrypoint.sh] Starting runner...
      [entrypoint.sh] Runner started - PID: 65 PGID: 1
      √ Connected to GitHub
      Current runner version: '2.328.0'
      2025-XX-XX XX:XX:XXZ: Listening for Jobs
      ```
    - **Interface GitHub :** Le runner doit apparaître comme "Idle" dans `Settings` > `Actions` > `Runners`.
    - Les logs du conteneur affichent également la liste des composants installés. Vous pouvez aussi consulter le fichier `/imagegeneration/installed/components.txt` dans le conteneur.

**Erreurs courantes :**
- **Échec de l'enregistrement :**
  ```
  Http response code: NotFound from 'POST https://api.github.com/actions/runner-registration'
  Response status code does not indicate success: 404 (Not Found).
  [entrypoint.sh][ERROR] Failed to configure runner
  ```
  Cette erreur est généralement due à un token expiré ou à une URL de dépôt/organisation incorrecte. Vérifiez les variables `RUNNER_REPO_URL` et `RUNNER_TOKEN` dans votre fichier `.env`.

---

### Tester localement vos workflows

Il est possible de tester vos workflows GitHub Actions en local pour faciliter le développement et le débogage. Des outils comme [act](https://github.com/nektos/act) simulent l'environnement d'exécution des actions. Les images de ce projet vous permettent de disposer d'un environnement de test fidèle avec une taille d'image optimisée.

> [!IMPORTANT]
> Pour fonctionner avec `act`, le composant `nodejs` doit être inclus dans l'image, en plus des composants requis par vos workflows. Toutes les images pré-construites `ghcr.io/jul-m/gha-runner-compose:u24.04-*` incluent `nodejs-lite`, qui est suffisant. L'image de base `ghcr.io/jul-m/gha-runner-compose-base:u24.04-latest` ne le contient pas.

Pour utiliser `act` avec `gha-runner-compose` :
- Si vous construisez une image personnalisée, suivez les instructions de la section [Générer des images personnalisées](#générer-des-images-personnalisées-sans-docker-compose).
- Utilisez l'option `-P` pour mapper les labels des runners aux images Docker. Par exemple, pour utiliser l'image `ghcr.io/jul-m/gha-runner-compose:u24.04-essentials-latest` pour les jobs `ubuntu-latest` :
  ```bash
  act -P ubuntu-latest=ghcr.io/jul-m/gha-runner-compose:u24.04-essentials-latest
  ```
- Si vous utilisez une image construite localement, ajoutez l'option `--pull=false` pour empêcher `act` de tenter de la télécharger depuis un registre public :
  ```bash
  act -P ubuntu-latest=<your-image-name> --pull=false
  ```
- En cas d'erreur `node: command not found`, vérifiez que le composant `nodejs` ou `nodejs-lite` est bien inclus dans votre image.
- Si vos workflows utilisent Docker (Docker-in-Docker), activez le mode privilégié avec `--privileged` et assurez-vous que le composant `docker` est présent dans l'image. **Attention aux implications de sécurité, ne l'activez que si vous avez pleinement conscience des risques et confiance dans le code que vous exécutez !**
- Pour plus de détails, consultez la [documentation officielle de `act`](https://nektosact.com/).

---

## Générer des images personnalisées (sans Docker Compose)
### Cas général
Vous pouvez construire des images personnalisées en utilisant `docker buildx build`. Pour accélérer le processus, il est recommandé de partir d'une image contenant déjà une partie des composants souhaités. Pour un contrôle total, partez de l'image de base `ghcr.io/jul-m/gha-runner-compose-base:u24.04-latest`.

**Commande de base :**
```bash
docker buildx build \
    --build-arg BASE_IMAGE=ghcr.io/jul-m/gha-runner-compose-base:u24.04-latest \
    --build-arg RUNNER_COMPONENTS=java-tools,yq \
    --target runner-build \
    -t my-gha-runner:java-latest .
```

**Arguments de build :**
- `--build-arg <arg>=<value>` :
    - `BASE_IMAGE` : Image de base à utiliser. Pour construire depuis une image Ubuntu 24.04 vierge, ne spécifiez pas cet argument ou définissez-le sur `base`.
    - `RUNNER_COMPONENTS` : Liste des composants et catégories (`all-<category>`) à inclure, séparés par des virgules. Les composants déjà présents dans l'image de base seront ignorés. La liste complète est disponible dans [docs/components.md](./docs/components.md).
    - `APT_PACKAGES` (optionnel) : Liste de paquets APT supplémentaires à installer, séparés par des virgules.
    - `PWSH_MODULES` (optionnel) : Liste de modules PowerShell supplémentaires à installer, séparés par des virgules (ex. `Microsoft.Graph,Az`).
- `--target <stage>` : Doit être `runner-build` pour une image fonctionnelle. Le stage `base` ne génère que la couche de prérequis.
- `-t <image-name>` : Nom de l'image résultante.
- `--platform <platform>` (optionnel) : Plateforme cible (ex. `linux/amd64`, `linux/arm64`). Nécessite un builder `buildx` configuré pour le multi-architecture.
- `--progress=plain` (optionnel) : Affiche les logs complets du build dans le terminal.
- `.` : Contexte de build (le répertoire racine de ce dépôt).

### Image de base

Pour construire l'image de base contenant uniquement les prérequis (équivalente à `ghcr.io/jul-m/gha-runner-compose-base:u24.04-latest`), utilisez le stage `base` :

```bash
docker buildx build \
    --target base \
    -t my-gha-runner-base:latest .
```

### Build avancé

Pour optimiser les builds multiples, vous pouvez utiliser un builder BuildKit dédié qui tire parti du cache des téléchargements.

1. **Créez le builder dédié :**
    ```bash
    docker buildx create --driver docker-container \
        --name gha-runner-compose-builder --config ./buildkitd.toml
    ```

2. **Lancez le build avec ce builder :**
    ```bash
    docker build --build-arg RUNNER_COMPONENTS=all \
        --target runner-build --progress=plain \
        -t my-gha-runner:all-latest \
        --builder gha-runner-compose-builder --load .
    ```
    L'option `--load` est nécessaire pour charger l'image dans le moteur Docker local.

#### Optionnel : augmenter les limites d’API GitHub pendant le build

Certains scripts téléchargent des artefacts depuis GitHub (releases, fichiers `raw`, etc.). Pour éviter les erreurs `403` dues aux limites d’accès anonymes, vous pouvez fournir un jeton GitHub à BuildKit sans qu’il soit conservé dans l’image finale. Les wrappers `curl` et `wget` injectent automatiquement un header `Authorization: Bearer` pour les domaines GitHub si un jeton est disponible.

1. Rendez le jeton accessible à BuildKit : soit via une variable d’environnement, soit via un fichier.
```bash
# Option A : variable d’environnement (utilisée par --secret env=...)
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxx

# Option B : fichier référencé plus tard
echo "ghp_xxxxxxxxxxxxxxxxxxxxx" > ~/.config/github-token
```
2. Passez le secret lors du build.
```bash
docker buildx build \
    --secret id=GITHUB_TOKEN,env=GITHUB_TOKEN \  # avec l’option A
    --build-arg RUNNER_COMPONENTS=yq,docker,java-tools \
    --target runner-build -t mon-runner:latest .

# ou avec l’option B
docker buildx build \
    --secret id=GITHUB_TOKEN,src=$HOME/.config/github-token \
    --build-arg RUNNER_COMPONENTS=yq,docker,java-tools \
    --target runner-build -t mon-runner:latest .
```
3. Exemple côté Docker Compose :
```yaml
build:
    context: .
    target: runner-build
    secrets:
        - GITHUB_TOKEN
secrets:
    GITHUB_TOKEN:
        environment: GITHUB_TOKEN  # ou: file: ~/.config/github-token
```

Rien n’est conservé dans l’image finale : le secret n’existe que le temps de l’exécution de chaque commande `RUN`. Si vous ne fournissez pas de secret, les téléchargements restent anonymes comme auparavant.

> [!NOTE]
> Les wrappers vérifient à la fois la variable d’environnement `GITHUB_TOKEN` et le fichier `/run/secrets/GITHUB_TOKEN`. Ils n’ajoutent pas le header si vous fournissez déjà une en-tête `Authorization`, ou si l’URL cible n’appartient pas à un domaine GitHub (`github.com`, `api.github.com`, `raw.githubusercontent.com`, `objects.githubusercontent.com`).

---

## Fonctionnement du build

Le pipeline de build s'appuie sur un `Dockerfile` multi-étapes et réutilise les scripts officiels de `actions/runner-images` (pour Ubuntu) avec des scripts locaux pour orchestrer l'installation des composants.

- **Provenance des scripts upstream :** Les scripts proviennent du sous-module Git `runner-images-src/`. Pour garantir la stabilité et la sécurité, une version figée de ces scripts est copiée dans `docker-assets/from-upstream/` et utilisée lors du build.

- **Étapes principales du `Dockerfile` :**
    1. **`base` :**
        - Copie les scripts upstream figés depuis `docker-assets/from-upstream/` vers `/imagegeneration/` et la logique locale depuis `docker-build/` vers `/imagegeneration/docker-build/`.
        - Active un cache APT pendant le build (désactive temporairement `docker-clean` et lie `zz-disable-apt-clean.conf`), installe les paquets de base, crée l'utilisateur `runner` et les répertoires, puis exécute `local-install/install-prereqs.sh` (installe le runner GitHub Actions, PowerShell, dépôts). Enfin, restaure la configuration APT via `local-install/clean-restore.sh`.
        - Prépare le démarrage du conteneur : copie `entrypoint.sh`, définit `ENTRYPOINT ["/entrypoint.sh"]`, `USER runner`, et `WORKDIR` sur `${RUNNER_WORKDIR}`.
    2. **`runner-build` :**
        - Hérite de `${BASE_IMAGE}` (par défaut le stage `base`). Il ne recopie pas les sources ; il s'attend à trouver `/imagegeneration/` dans l'image de base.
        - Réactive l’optimisation de cache APT durant l’installation des composants, exécute `local-install/install-components.sh` piloté par `RUNNER_COMPONENTS` ainsi que les options `APT_PACKAGES` et `PWSH_MODULES`, puis restaure la configuration APT.
        - Résout les dépendances et catégories (`all`, `all-<category>`) définies dans `local-install/components.csv`, et enregistre les composants installés dans `/imagegeneration/installed/components.txt` pour éviter les réinstallations.
    3. **Image résultante :**
        - Le stage `runner-build` est celui qu’il faut taguer/utiliser comme image finale.

- **Logique d'override par composant :**
    - Pour chaque composant `<comp>`, l'orchestrateur cherche d'abord un script local `docker-build/components/<comp>.sh`.
    - **S'il existe :** ce script est exécuté. Il a la possibilité de modifier le script upstream correspondant (par exemple, pour l'adapter à ARM64 ou à un contexte conteneur) avant de l'appeler.
    - **Sinon :** le script upstream `/imagegeneration/build/install-<comp>.sh` est exécuté directement.

- **Wrappers utilitaires (`./docker-build/bin/`) :**
    - `systemctl` : Un faux `systemd` qui redirige les appels vers `service` ou des scripts `init.d`, permettant aux scripts upstream de fonctionner dans un conteneur.
    - `curl` et `wget` : Wrappers qui mettent en cache les artefacts téléchargés dans `/var/cache/gha-download-cache` (mis en cache par BuildKit), réduisant ainsi les temps de build. Les métadonnées et paquets APT sont également mis en cache via les mounts BuildKit.

---

## Entrypoint

Le script `/entrypoint.sh` gère le cycle de vie du runner dans le conteneur :
- **Vérifications initiales :** Exige la présence de `RUNNER_TOKEN` au premier démarrage.
- **Configuration des labels :** Applique des labels par défaut (`docker-runner`, `docker-runner-<arch>`) si `RUNNER_LABELS` n'est pas défini.
- **Gestion du runner :** S'assure que le binaire du runner est présent et affiche la liste des composants installés.
- **Enregistrement conditionnel :** Exécute `config.sh` uniquement si le runner n'est pas déjà configuré (c'est-à-dire si le fichier `.runner` n'existe pas).
- **Exécution et arrêt propre :** Lance `run.sh` en arrière-plan et intercepte les signaux (`SIGINT`, `SIGTERM`) pour garantir un arrêt gracieux du runner.

---

## Structure du dépôt

- `Dockerfile` : Fichier de build multi-étapes.
- `compose.*.yml` : Fichiers Docker Compose pour différents scénarios d'utilisation.
- `buildkitd.toml` : Configuration BuildKit pour le cache des builds.
- `docker-assets/` : Fichiers copiés dans l'image Docker.
    - `entrypoint.sh` : Script de démarrage du conteneur.
    - `from-upstream/` : Copie figée des scripts et du `toolset.json` de `actions/runner-images`.
- `docker-build/` : Logique de build personnalisée.
    - `local-install/` : Scripts d'orchestration (`install-prereqs.sh`, `install-components.sh`), `helpers.sh`, et `components.csv` (définition des composants).
    - `components/` : Scripts d'override pour adapter les installations de composants spécifiques.
    - `bin/` : Wrappers pour `systemctl`, `curl`, et `wget`.
- `docs/` : Documentation additionnelle (composants, images).
- `runner-images-src/` (sous-module Git) : Miroir du dépôt `actions/runner-images`, utilisé comme source pour les scripts upstream.

---

## Licence
- **Sources upstream (`runner-images-src/`, `docker-assets/from-upstream/`) :** Ces contenus proviennent de `actions/runner-images` et sont distribués sous la licence MIT originale. Les droits d'auteur appartiennent à "Microsoft Corporation and contributors".
- **Ce dépôt (code original) :** Sauf mention contraire, le code est régi par la licence spécifiée dans le fichier [LICENCE](LICENCE) à la racine du dépôt. Ce projet est indépendant et n'est ni affilié, ni sponsorisé, ni approuvé par GitHub, Inc. ou Microsoft Corporation.

---

## Avertissement — Absence de garantie et limitation de responsabilité
Ce projet est fourni « en l’état » (AS IS), sans aucune garantie expresse ou implicite, y compris, sans limitation, les garanties de qualité marchande, d’adéquation à un usage particulier et d’absence de contrefaçon.
En aucun cas l’auteur ou les contributeurs ne pourront être tenus responsables de tout dommage direct, indirect, accessoire, spécial, exemplaire ou consécutif résultant de l’utilisation ou de l’impossibilité d’utiliser ce projet.
Vous utilisez ce projet à vos propres risques et êtes seul responsable du respect des lois, politiques de sécurité et obligations contractuelles applicables.
