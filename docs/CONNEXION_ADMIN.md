# Connexion au tableau de bord administrateur — ReTurn

Procédure complète pour se connecter en **administrateur** au dashboard web
(`admin/index.html`).

> Résumé : l'admin se connecte par **numéro + code OTP** (comme un utilisateur),
> mais son compte doit avoir le **rôle administrateur** (`is_admin = true`).
> En environnement de **dev**, le code OTP est fourni automatiquement par l'API
> (pas besoin de SMS).

---

## 0. Prérequis

- Docker installé, et le backend démarré (Postgres + Redis + MinIO + API).
- Un numéro de téléphone au format **E.164** (ex. `+237699000000`).

---

## 1. Démarrer le backend

```bash
cd infra
docker compose up -d
docker compose ps                 # tous les services "Up/healthy"
docker compose logs -f backend    # attendre : "Application startup complete."
```

L'API écoute sur `http://localhost:8000` (et `http://<IP-de-ce-PC>:8000` sur le réseau local).

---

## 2. Faire exister le compte en base

Le compte doit exister **avant** de pouvoir être promu admin. Deux façons :

**Option A — via le dashboard (le plus simple)**
1. Ouvre `admin/index.html` (voir §4 pour l'ouverture).
2. Saisis ton **numéro** → clique **« Recevoir le code »**.
   - En dev, le code s'affiche/se remplit tout seul.
3. Clique **« Se connecter »**.
   → Tu obtiens : *« Ce compte existe, mais il n'a pas encore le rôle administrateur. »*
   **C'est normal** : le compte vient d'être créé en base.

**Option B — via l'app mobile**
- Connecte-toi une fois dans l'app ReTurn avec ce numéro (OTP). Le compte est créé.

---

## 3. Promouvoir le compte en administrateur

Depuis le **repo** (ou depuis `infra/`), exécute le script dans le conteneur backend :

```bash
# depuis la racine du repo
docker compose -f infra/docker-compose.yml exec backend python promote_admin.py +237699000000
```
```bash
# OU depuis le dossier infra/
cd infra
docker compose exec backend python promote_admin.py +237699000000
```

Résultat attendu :
```
[OK] +237699000000 (id=...) est maintenant administrateur.
```

> Si tu obtiens `[ERREUR] Aucun utilisateur trouvé` → reviens à l'étape 2
> (le compte n'existe pas encore en base).

---

## 4. Ouvrir le dashboard admin

Le dashboard est un fichier statique : `admin/index.html`.

**Méthode simple (dev)** : double-clique le fichier pour l'ouvrir dans le navigateur
(le backend autorise l'origine `file://` en mode développement).

**Méthode recommandée (servi en HTTP)** :
```bash
cd admin
python -m http.server 3000
# puis ouvre http://localhost:3000
```

### Indiquer l'URL de l'API (si besoin)
Par défaut le dashboard cible `http://localhost:8000`. Si ton backend est ailleurs
(ex. IP du PC), précise-le **une fois** via le paramètre `?api=` :

```
http://localhost:3000/index.html?api=http://192.168.1.99:8000
file:///C:/Users/.../Docretour/admin/index.html?api=http://192.168.1.99:8000
```
L'URL est ensuite mémorisée dans le navigateur.

---

## 5. Se connecter

1. Saisis ton **numéro administrateur** (le même qu'à l'étape 3).
2. Clique **« Recevoir le code »**.
   - **Dev** : le code OTP est renvoyé par l'API et **rempli automatiquement**
     (message « Code OTP récupéré depuis l'API locale : … »).
3. Clique **« Se connecter »**.
   → Le tableau de bord se charge : Utilisateurs, Déclarations, Matchs,
   Restitutions, Signalements, **Vérifications**, Zones certifiées, Audit.

La session (token) est conservée dans le navigateur ; tu restes connecté jusqu'à
la déconnexion.

---

## Pourquoi le code OTP s'affiche tout seul ?

Le dashboard utilise l'OTP **backend** (`/auth/otp/request` + `/auth/otp/verify`).
Quand `ENVIRONMENT=development` et `DEBUG=true` (valeurs par défaut de
`infra/.env`), l'API renvoie le code dans la réponse (`debug_code`) pour
faciliter les tests — **aucun SMS n'est envoyé**.

> ⚠️ **En production** (`ENVIRONMENT=production`), `debug_code` n'est plus renvoyé.
> Il faudra alors brancher une vraie passerelle SMS (Twilio / Orange CM) sur
> l'OTP backend, ou réserver l'accès admin à une liste de numéros via un canal
> sécurisé. (À prévoir avant mise en prod.)

---

## Dépannage

| Symptôme | Cause / Solution |
|---|---|
| « …pas encore le rôle administrateur » | Compte non promu → étape 3 (`promote_admin.py`). |
| « Aucun utilisateur trouvé » (script) | Le compte n'existe pas → étape 2 d'abord. |
| Le code OTP ne s'affiche pas | `DEBUG=true` et `ENVIRONMENT=development` dans `infra/.env` ? Redémarre le backend. |
| Données vides / erreurs réseau | Mauvaise URL API → ouvre avec `?api=http://<ip>:8000`. Vérifie que le backend tourne. |
| « Connexion impossible » | Backend injoignable (pare-feu/port 8000) ou numéro mal formaté (E.164 `+237…`). |
| Tout reste vide après login | Le compte est admin mais aucune donnée n'existe encore — crée des utilisateurs/zones de test. |

---

## Créer une zone certifiée (pour tester F-32 côté mobile)

Une fois connecté en admin : menu **« Zones certifiées » → « + Nouvelle zone »**
(nom, type, adresse, latitude, longitude). Elle apparaîtra ensuite dans l'app
mobile (Profil → « Zones de récupération » et au choix du lieu de restitution).
