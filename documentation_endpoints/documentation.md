# 📚 API Hopital NK - Documentation Complète Enrichie (Postman-Ready)

## ⚙️ CONFIGURATION POSTMAN

### Variables d'environnement Postman

| Variable | Valeur initiale | Description |
|----------|----------------|-------------|
| `base_url` | `http://localhost/hospital/api` | URL de base |
| `access_token` | *(vide - rempli auto après login)* | JWT Token |
| `refresh_token` | *(vide - rempli auto après login)* | Refresh Token |
| `user_id` | *(vide)* | ID utilisateur courant |
| `exercice_id` | `1` | Exercice fiscal courant |

### Script Pre-request Global (Collection Level)

```javascript
// A mettre dans "Pre-request Script" de la Collection
pm.request.headers.add({
    key: 'Content-Type',
    value: 'application/json'
});

if (pm.environment.get('access_token')) {
    pm.request.headers.add({
        key: 'Authorization',
        value: 'Bearer ' + pm.environment.get('access_token')
    });
}
```

---

## 🔐 MODULE AUTH

---

### 1. POST `/auth/login`

**Description:** Authentification et récupération des tokens JWT

**URL:** `{{base_url}}/auth/login`

**Méthode:** `POST`

**Headers:**
```
Content-Type: application/json
```
> ⚠️ Pas de `Authorization` header ici

**Body (JSON):**
```json
{
  "email": "admin@hopital-nk.cd",
  "password": "Admin@2024"
}
```

**Autres comptes de test:**
```json
{ "email": "comptable@hopital-nk.cd", "password": "password" }
{ "email": "caissier@hopital-nk.cd", "password": "password" }
{ "email": "directeur@hopital-nk.cd", "password": "password" }
```

**Réponse succès (200):**
```json
{
  "success": true,
  "message": "Connexion réussie",
  "data": {
    "user": {
      "id": 1,
      "matricule": "ADM-001",
      "nom": "ADMIN",
      "prenom": "Super",
      "email": "admin@hopital-nk.cd",
      "role": {
        "id": 1,
        "nom": "Administrateur",
        "slug": "admin"
      },
      "service": {
        "id": 1,
        "nom": "Direction Générale"
      },
      "derniere_connexion": "2024-03-15T08:30:00Z"
    },
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "token_type": "Bearer",
    "expires_in": 3600
  }
}
```

**Script Test Postman (auto-save token):**
```javascript
if (pm.response.code === 200) {
    const res = pm.response.json();
    pm.environment.set('access_token', res.data.access_token);
    pm.environment.set('refresh_token', res.data.refresh_token);
    pm.environment.set('user_id', res.data.user.id);
    console.log('✅ Token sauvegardé:', res.data.access_token.substring(0, 30) + '...');
}

pm.test("Status 200", () => pm.response.to.have.status(200));
pm.test("Token présent", () => pm.expect(pm.response.json().data.access_token).to.not.be.empty);
```

**Réponses erreur:**

*Email incorrect (401):*
```json
{
  "success": false,
  "message": "Email ou mot de passe incorrect"
}
```

*Compte verrouillé (423):*
```json
{
  "success": false,
  "message": "Compte verrouillé suite à trop de tentatives. Réessayez dans 15 minutes.",
  "data": {
    "locked_until": "2024-03-15T09:00:00Z",
    "tentatives": 5
  }
}
```

*Champ manquant (422):*
```json
{
  "success": false,
  "message": "Validation échouée",
  "errors": {
    "email": ["Le champ email est requis"],
    "password": ["Le champ password est requis"]
  }
}
```

---

### 2. GET `/auth/me`

**Description:** Récupérer le profil de l'utilisateur connecté

**URL:** `{{base_url}}/auth/me`

**Méthode:** `GET`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body:** *(aucun)*

**Réponse succès (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "matricule": "ADM-001",
    "nom": "ADMIN",
    "prenom": "Super",
    "email": "admin@hopital-nk.cd",
    "telephone": "+243812345678",
    "photo": null,
    "statut": "ACTIF",
    "role": {
      "id": 1,
      "nom": "Administrateur",
      "slug": "admin",
      "permissions": [
        "users.view", "users.create", "users.edit", "users.delete",
        "ecritures.view", "ecritures.create", "ecritures.valider"
      ]
    },
    "service": {
      "id": 1,
      "nom": "Direction Générale",
      "code": "DG"
    },
    "derniere_connexion": "2024-03-15T08:30:00Z",
    "created_at": "2024-01-01T00:00:00Z"
  }
}
```

**Réponse erreur (401) - Token absent ou expiré:**
```json
{
  "success": false,
  "message": "Token invalide ou expiré. Veuillez vous reconnecter."
}
```

---

### 3. POST `/auth/refresh`

**Description:** Renouveler le token d'accès

**URL:** `{{base_url}}/auth/refresh`

**Méthode:** `POST`

**Headers:**
```
Content-Type: application/json
```

**Body (JSON):**
```json
{
  "refresh_token": "{{refresh_token}}"
}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "message": "Token renouvelé avec succès",
  "data": {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "token_type": "Bearer",
    "expires_in": 3600
  }
}
```

**Script Test:**
```javascript
if (pm.response.code === 200) {
    const res = pm.response.json();
    pm.environment.set('access_token', res.data.access_token);
    pm.environment.set('refresh_token', res.data.refresh_token);
    console.log('✅ Token rafraîchi');
}
pm.test("Refresh OK", () => pm.response.to.have.status(200));
```

**Erreur refresh_token invalide (401):**
```json
{
  "success": false,
  "message": "Refresh token invalide ou expiré"
}
```

---

### 4. POST `/auth/logout`

**Description:** Déconnexion (révocation du token)

**URL:** `{{base_url}}/auth/logout`

**Méthode:** `POST`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body:** *(aucun)*

**Réponse succès (200):**
```json
{
  "success": true,
  "message": "Déconnexion réussie"
}
```

**Script Test:**
```javascript
if (pm.response.code === 200) {
    pm.environment.unset('access_token');
    pm.environment.unset('refresh_token');
    console.log('✅ Tokens supprimés de l\'environnement');
}
pm.test("Logout OK", () => pm.response.to.have.status(200));
```

---

### 5. POST `/auth/change-password`

**Description:** Changer le mot de passe

**URL:** `{{base_url}}/auth/change-password`

**Méthode:** `POST`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body (JSON):**
```json
{
  "current_password": "password",
  "new_password": "NouveauMotDePasse@2024!",
  "new_password_confirmation": "NouveauMotDePasse@2024!"
}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "message": "Mot de passe modifié avec succès"
}
```

**Erreurs possibles:**

*Ancien mot de passe incorrect (422):*
```json
{
  "success": false,
  "message": "Le mot de passe actuel est incorrect"
}
```

*Confirmation non identique (422):*
```json
{
  "success": false,
  "message": "Validation échouée",
  "errors": {
    "new_password_confirmation": ["La confirmation du mot de passe ne correspond pas"]
  }
}
```

*Mot de passe trop faible (422):*
```json
{
  "success": false,
  "message": "Le mot de passe doit contenir au moins 8 caractères, une majuscule, un chiffre et un caractère spécial"
}
```

---

## 👥 MODULE UTILISATEURS

---

### 1. GET `/users`

**Description:** Lister les utilisateurs avec pagination et filtres

**URL:** `{{base_url}}/users`

**Méthode:** `GET`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Query Parameters:**

| Paramètre | Type | Requis | Exemple | Description |
|-----------|------|--------|---------|-------------|
| `page` | int | Non | `1` | Page courante |
| `per_page` | int | Non | `20` | Items par page |
| `role_id` | int | Non | `3` | Filtrer par rôle |
| `service_id` | int | Non | `2` | Filtrer par service |
| `statut` | string | Non | `ACTIF` | `ACTIF`, `INACTIF`, `SUSPENDU` |
| `search` | string | Non | `jean` | Recherche nom/prénom/email/matricule |

**URL complète exemple:**
```
{{base_url}}/users?page=1&per_page=20&role_id=3&statut=ACTIF&search=jean
```

**Réponse succès (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": 2,
        "matricule": "CPT-001",
        "nom": "KABILA",
        "prenom": "Jean",
        "email": "jean@hopital.cd",
        "telephone": "+243812345678",
        "statut": "ACTIF",
        "role": { "id": 5, "nom": "Comptable", "slug": "comptable" },
        "service": { "id": 2, "nom": "Comptabilité", "code": "CPT" },
        "derniere_connexion": "2024-03-14T16:00:00Z",
        "created_at": "2024-01-15T09:00:00Z"
      }
    ],
    "pagination": {
      "total": 45,
      "per_page": 20,
      "current_page": 1,
      "last_page": 3,
      "from": 1,
      "to": 20
    }
  }
}
```

---

### 2. POST `/users`

**Description:** Créer un nouvel utilisateur

**URL:** `{{base_url}}/users`

**Méthode:** `POST`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body (JSON) - Complet:**
```json
{
  "matricule": "CPT-001",
  "nom": "KABILA",
  "prenom": "Jean",
  "email": "jean.kabila@hopital-nk.cd",
  "password": "@password",
  "role_id": 5,
  "service_id": 2,
  "telephone": "+243812345678",
  "statut": "ACTIF"
}
```

**Body (JSON) - Minimal requis:**
```json
{
  "nom": "MWAMBA",
  "prenom": "Pierre",
  "email": "pierre.mwamba@hopital-nk.cd",
  "role_id": 3
}
```

**Réponse succès (201):**
```json
{
  "success": true,
  "message": "Utilisateur créé avec succès",
  "data": {
    "id": 15,
    "matricule": "CPT-001",
    "nom": "KABILA",
    "prenom": "Jean",
    "email": "jean.kabila@hopital-nk.cd",
    "role": { "id": 5, "nom": "Comptable" },
    "service": { "id": 2, "nom": "Comptabilité" },
    "statut": "ACTIF",
    "created_at": "2024-03-15T10:00:00Z"
  }
}
```

**Erreur email déjà utilisé (422):**
```json
{
  "success": false,
  "message": "Validation échouée",
  "errors": {
    "email": ["Cet email est déjà utilisé"],
    "matricule": ["Ce matricule existe déjà"]
  }
}
```

**Erreur permission (403):**
```json
{
  "success": false,
  "message": "Vous n'avez pas la permission de créer des utilisateurs"
}
```

---

### 3. GET `/users/{id}`

**Description:** Détail d'un utilisateur

**URL:** `{{base_url}}/users/1`

**Méthode:** `GET`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "matricule": "ADM-001",
    "nom": "ADMIN",
    "prenom": "Super",
    "email": "admin@hopital-nk.cd",
    "telephone": "+243812345678",
    "statut": "ACTIF",
    "role": {
      "id": 1,
      "nom": "Administrateur",
      "slug": "admin",
      "permissions": ["users.view", "users.create"]
    },
    "service": { "id": 1, "nom": "Direction Générale" },
    "derniere_connexion": "2024-03-15T08:30:00Z",
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-03-10T12:00:00Z"
  }
}
```

**Erreur non trouvé (404):**
```json
{
  "success": false,
  "message": "Utilisateur non trouvé"
}
```

---

### 4. PUT `/users/{id}`

**URL:** `{{base_url}}/users/1`

**Méthode:** `PUT`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body (JSON):**
```json
{
  "nom": "KABILA",
  "prenom": "Jean-Paul",
  "telephone": "+243898765432",
  "service_id": 3,
  "statut": "ACTIF"
}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "message": "Utilisateur mis à jour avec succès",
  "data": {
    "id": 1,
    "nom": "KABILA",
    "prenom": "Jean-Paul",
    "updated_at": "2024-03-15T11:00:00Z"
  }
}
```

---

### 5. DELETE `/users/{id}`

**URL:** `{{base_url}}/users/5`

**Méthode:** `DELETE`

**Headers:**
```
Authorization: Bearer {{access_token}}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "message": "Utilisateur supprimé avec succès"
}
```

**Erreur suppression compte propre (400):**
```json
{
  "success": false,
  "message": "Vous ne pouvez pas supprimer votre propre compte"
}
```

---

### 6. POST `/users/{id}/reset-password`

**URL:** `{{base_url}}/users/5/reset-password`

**Méthode:** `POST`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body (JSON):**
```json
{
  "new_password": "Reset@2024!"
}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "message": "Mot de passe réinitialisé avec succès"
}
```

---

## 🎭 MODULE ROLES

---

### 1. GET `/roles`

**URL:** `{{base_url}}/roles`

**Méthode:** `GET`

**Headers:**
```
Authorization: Bearer {{access_token}}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "nom": "Administrateur",
      "slug": "admin",
      "description": "Accès complet au système",
      "nb_utilisateurs": 2,
      "permissions_count": 45
    },
    {
      "id": 2,
      "nom": "Directeur Financier",
      "slug": "directeur-financier",
      "description": "Validation et supervision financière",
      "nb_utilisateurs": 1,
      "permissions_count": 30
    },
    {
      "id": 3,
      "nom": "Comptable",
      "slug": "comptable",
      "description": "Saisie et gestion comptable",
      "nb_utilisateurs": 5,
      "permissions_count": 20
    },
    {
      "id": 4,
      "nom": "Caissier",
      "slug": "caissier",
      "description": "Gestion caisse et transactions",
      "nb_utilisateurs": 8,
      "permissions_count": 10
    }
  ]
}
```

---

### 2. GET `/roles/permissions`

**URL:** `{{base_url}}/roles/permissions`

**Méthode:** `GET`

**Headers:**
```
Authorization: Bearer {{access_token}}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "data": {
    "users": ["users.view", "users.create", "users.edit", "users.delete"],
    "ecritures": ["ecritures.view", "ecritures.create", "ecritures.soumettre", "ecritures.valider", "ecritures.rejeter"],
    "budgets": ["budgets.view", "budgets.create", "budgets.approuver"],
    "caisse": ["caisse.ouvrir", "caisse.fermer", "caisse.transactions"],
    "rapports": ["rapports.view", "rapports.export"],
    "stock": ["stock.view", "stock.create", "stock.edit", "stock.delete"],
    "salaires": ["salaires.view", "salaires.create", "salaires.valider", "salaires.payer"]
  }
}
```

---

### 3. POST `/roles`

**URL:** `{{base_url}}/roles`

**Méthode:** `POST`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body (JSON):**
```json
{
  "nom": "Auditeur Interne",
  "slug": "auditeur-interne",
  "description": "Consultation et audit des écritures",
  "permissions": [
    "users.view",
    "ecritures.view",
    "budgets.view",
    "rapports.view",
    "rapports.export"
  ]
}
```

**Réponse succès (201):**
```json
{
  "success": true,
  "message": "Rôle créé avec succès",
  "data": {
    "id": 8,
    "nom": "Auditeur Interne",
    "slug": "auditeur-interne",
    "description": "Consultation et audit des écritures",
    "permissions": ["users.view", "ecritures.view", "rapports.view"],
    "created_at": "2024-03-15T10:00:00Z"
  }
}
```

---

## 🏥 MODULE SERVICES

---

### 1. GET `/services`

**URL:** `{{base_url}}/services`

**Méthode:** `GET`

**Headers:**
```
Authorization: Bearer {{access_token}}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "nom": "Direction Générale",
      "code": "DG",
      "type": "ADMINISTRATIF",
      "responsable": {
        "id": 1,
        "nom": "ADMIN",
        "prenom": "Super"
      },
      "budget_annuel": 5000000,
      "nb_employes": 3,
      "statut": "ACTIF"
    },
    {
      "id": 2,
      "nom": "Comptabilité",
      "code": "CPT",
      "type": "ADMINISTRATIF",
      "responsable": null,
      "budget_annuel": 2000000,
      "nb_employes": 5,
      "statut": "ACTIF"
    },
    {
      "id": 3,
      "nom": "Médecine Interne",
      "code": "MED",
      "type": "MEDICAL",
      "responsable": null,
      "budget_annuel": 8000000,
      "nb_employes": 12,
      "statut": "ACTIF"
    }
  ]
}
```

---

### 2. POST `/services`

**URL:** `{{base_url}}/services`

**Méthode:** `POST`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body (JSON):**
```json
{
  "nom": "Pharmacie Centrale",
  "code": "PHARM",
  "type": "MEDICAL",
  "responsable_id": 5,
  "budget_annuel": 3000000,
  "description": "Gestion médicaments et consommables"
}
```

**Réponse succès (201):**
```json
{
  "success": true,
  "message": "Service créé avec succès",
  "data": {
    "id": 8,
    "nom": "Pharmacie Centrale",
    "code": "PHARM",
    "type": "MEDICAL",
    "statut": "ACTIF",
    "created_at": "2024-03-15T10:00:00Z"
  }
}
```

**Erreur code dupliqué (422):**
```json
{
  "success": false,
  "message": "Validation échouée",
  "errors": {
    "code": ["Ce code de service existe déjà"]
  }
}
```

---

### 3. GET `/services/{id}/budget`

**URL:** `{{base_url}}/services/2/budget?exercice_id=1`

**Méthode:** `GET`

**Headers:**
```
Authorization: Bearer {{access_token}}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "data": {
    "service": { "id": 2, "nom": "Comptabilité" },
    "exercice": { "id": 1, "annee": 2024 },
    "budget_alloue": 2000000,
    "budget_consomme": 850000,
    "budget_restant": 1150000,
    "taux_execution": 42.5,
    "lignes_budgetaires": [
      {
        "compte": "Charges de personnel",
        "montant_prevu": 1200000,
        "montant_realise": 600000,
        "ecart": 600000
      },
      {
        "compte": "Fournitures bureau",
        "montant_prevu": 200000,
        "montant_realise": 150000,
        "ecart": 50000
      }
    ]
  }
}
```

---

## 📅 MODULE EXERCICES FISCAUX

---

### 1. GET `/exercices`

**URL:** `{{base_url}}/exercices`

**Méthode:** `GET`

**Headers:**
```
Authorization: Bearer {{access_token}}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "annee": 2024,
      "date_debut": "2024-01-01",
      "date_fin": "2024-12-31",
      "statut": "OUVERT",
      "is_current": true,
      "nb_ecritures": 248,
      "total_debit": 125000000,
      "total_credit": 125000000
    },
    {
      "id": 2,
      "annee": 2023,
      "date_debut": "2023-01-01",
      "date_fin": "2023-12-31",
      "statut": "CLOTURE",
      "is_current": false,
      "nb_ecritures": 1250,
      "total_debit": 450000000,
      "total_credit": 450000000
    }
  ]
}
```

---

### 2. GET `/exercices/current`

**URL:** `{{base_url}}/exercices/current`

**Méthode:** `GET`

**Headers:**
```
Authorization: Bearer {{access_token}}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "annee": 2024,
    "date_debut": "2024-01-01",
    "date_fin": "2024-12-31",
    "statut": "OUVERT",
    "is_current": true,
    "jours_restants": 291
  }
}
```

---

### 3. POST `/exercices`

**URL:** `{{base_url}}/exercices`

**Méthode:** `POST`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body (JSON):**
```json
{
  "annee": 2025,
  "date_debut": "2025-01-01",
  "date_fin": "2025-12-31"
}
```

**Réponse succès (201):**
```json
{
  "success": true,
  "message": "Exercice fiscal 2025 créé avec succès",
  "data": {
    "id": 3,
    "annee": 2025,
    "date_debut": "2025-01-01",
    "date_fin": "2025-12-31",
    "statut": "OUVERT",
    "created_at": "2024-03-15T10:00:00Z"
  }
}
```

---

### 4. PUT `/exercices/{id}/cloturer`

**URL:** `{{base_url}}/exercices/1/cloturer`

**Méthode:** `PUT`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body (JSON):**
```json
{
  "commentaire": "Clôture exercice 2024 après validation du bilan"
}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "message": "Exercice 2024 clôturé avec succès",
  "data": {
    "id": 1,
    "statut": "CLOTURE",
    "date_cloture": "2024-12-31",
    "cloture_par": "ADMIN Super"
  }
}
```

**Erreur écritures non validées (400):**
```json
{
  "success": false,
  "message": "Impossible de clôturer: 12 écriture(s) en attente de validation",
  "data": {
    "ecritures_en_attente": 12
  }
}
```

---

## 📊 MODULE PLAN COMPTABLE

---

### 1. GET `/plan-comptable`

**URL:** `{{base_url}}/plan-comptable?page=1&classe=6&search=charge`

**Méthode:** `GET`

**Headers:**
```
Authorization: Bearer {{access_token}}
```

**Query Parameters:**

| Paramètre | Type | Exemple | Description |
|-----------|------|---------|-------------|
| `page` | int | `1` | Page |
| `per_page` | int | `50` | Items/page |
| `classe` | int | `6` | Classe comptable (1-9) |
| `type` | string | `CHARGE` | `CHARGE`, `PRODUIT`, `BILAN` |
| `search` | string | `caisse` | Recherche code/libellé |
| `actif` | bool | `1` | Comptes actifs seulement |

**Réponse succès (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": 1,
        "code": "101000",
        "libelle": "Capital social",
        "classe": 1,
        "type": "BILAN",
        "sens_normal": "CREDIT",
        "compte_parent_id": null,
        "compte_parent": null,
        "is_detail": true,
        "is_actif": true,
        "solde_debit": 0,
        "solde_credit": 5000000
      },
      {
        "id": 10,
        "code": "571000",
        "libelle": "Caisse principale",
        "classe": 5,
        "type": "BILAN",
        "sens_normal": "DEBIT",
        "compte_parent_id": null,
        "is_detail": true,
        "is_actif": true,
        "solde_debit": 150000,
        "solde_credit": 0
      }
    ],
    "pagination": {
      "total": 120,
      "per_page": 50,
      "current_page": 1,
      "last_page": 3
    }
  }
}
```

---

### 2. GET `/plan-comptable/arborescence`

**URL:** `{{base_url}}/plan-comptable/arborescence`

**Méthode:** `GET`

**Headers:**
```
Authorization: Bearer {{access_token}}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "data": [
    {
      "classe": 1,
      "libelle": "Comptes de capitaux",
      "comptes": [
        {
          "id": 1,
          "code": "10",
          "libelle": "Capital et réserves",
          "enfants": [
            { "id": 2, "code": "101", "libelle": "Capital social", "enfants": [] }
          ]
        }
      ]
    },
    {
      "classe": 5,
      "libelle": "Comptes de trésorerie",
      "comptes": [
        {
          "id": 9,
          "code": "57",
          "libelle": "Caisse",
          "enfants": [
            { "id": 10, "code": "571000", "libelle": "Caisse principale", "enfants": [] }
          ]
        }
      ]
    }
  ]
}
```

---

### 3. POST `/plan-comptable`

**URL:** `{{base_url}}/plan-comptable`

**Méthode:** `POST`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body (JSON):**
```json
{
  "code": "604100",
  "libelle": "Médicaments et consommables médicaux",
  "classe": 6,
  "type": "CHARGE",
  "sens_normal": "DEBIT",
  "compte_parent_id": null,
  "is_detail": true,
  "description": "Achats médicaments usage courant"
}
```

**Réponse succès (201):**
```json
{
  "success": true,
  "message": "Compte comptable créé avec succès",
  "data": {
    "id": 45,
    "code": "604100",
    "libelle": "Médicaments et consommables médicaux",
    "classe": 6,
    "type": "CHARGE",
    "created_at": "2024-03-15T10:00:00Z"
  }
}
```

---

## 📒 MODULE JOURNAUX

---

### 1. GET `/journaux`

**URL:** `{{base_url}}/journaux`

**Méthode:** `GET`

**Headers:**
```
Authorization: Bearer {{access_token}}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "code": "JNL-VTE",
      "nom": "Journal des Ventes",
      "type": "VENTE",
      "is_actif": true,
      "nb_ecritures": 145
    },
    {
      "id": 2,
      "code": "JNL-ACH",
      "nom": "Journal des Achats",
      "type": "ACHAT",
      "is_actif": true,
      "nb_ecritures": 89
    },
    {
      "id": 3,
      "code": "JNL-CAI",
      "nom": "Journal de Caisse",
      "type": "CAISSE",
      "is_actif": true,
      "nb_ecritures": 320
    },
    {
      "id": 4,
      "code": "JNL-OPD",
      "nom": "Journal des Opérations Diverses",
      "type": "OD",
      "is_actif": true,
      "nb_ecritures": 56
    }
  ]
}
```

---

### 2. POST `/journaux`

**URL:** `{{base_url}}/journaux`

**Méthode:** `POST`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body (JSON):**
```json
{
  "code": "JNL-BNK",
  "nom": "Journal Banque RAWBANK",
  "type": "BANQUE",
  "description": "Mouvements compte bancaire RAWBANK"
}
```

**Réponse succès (201):**
```json
{
  "success": true,
  "message": "Journal créé avec succès",
  "data": {
    "id": 5,
    "code": "JNL-BNK",
    "nom": "Journal Banque RAWBANK",
    "type": "BANQUE",
    "is_actif": true,
    "created_at": "2024-03-15T10:00:00Z"
  }
}
```

---

### 3. GET `/journaux/{id}/ecritures`

**URL:** `{{base_url}}/journaux/1/ecritures?exercice_id=1&page=1`

**Méthode:** `GET`

**Headers:**
```
Authorization: Bearer {{access_token}}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "data": {
    "journal": { "id": 1, "nom": "Journal des Ventes" },
    "items": [
      {
        "id": 10,
        "numero": "JNL-VTE-2024-0010",
        "date_ecriture": "2024-03-15",
        "libelle": "Consultation médecine interne - MWAMBA",
        "statut": "VALIDE",
        "total_debit": 25000,
        "total_credit": 25000,
        "nb_lignes": 2,
        "saisie_par": "Jean KABILA"
      }
    ],
    "pagination": {
      "total": 145,
      "per_page": 20,
      "current_page": 1,
      "last_page": 8
    }
  }
}
```

---

## 💰 MODULE ECRITURES COMPTABLES

---

### 1. GET `/ecritures`

**URL:** `{{base_url}}/ecritures?page=1&exercice_id=1&statut=SOUMIS`

**Méthode:** `GET`

**Headers:**
```
Authorization: Bearer {{access_token}}
```

**Query Parameters:**

| Paramètre | Type | Exemple | Description |
|-----------|------|---------|-------------|
| `page` | int | `1` | Page |
| `exercice_id` | int | `1` | Exercice fiscal |
| `journal_id` | int | `1` | Journal |
| `statut` | string | `SOUMIS` | `BROUILLON`, `SOUMIS`, `VALIDE`, `REJETE` |
| `date_debut` | date | `2024-01-01` | Filtrer depuis |
| `date_fin` | date | `2024-03-31` | Filtrer jusqu'à |
| `search` | string | `MWAMBA` | Recherche libellé/numéro |
| `compte_id` | int | `10` | Filtre par compte |

**Réponse succès (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": 10,
        "numero": "JNL-VTE-2024-0010",
        "date_ecriture": "2024-03-15",
        "libelle": "Consultation médecine interne - MWAMBA",
        "journal": { "id": 1, "nom": "Journal des Ventes", "code": "JNL-VTE" },
        "exercice": { "id": 1, "annee": 2024 },
        "statut": "SOUMIS",
        "total_debit": 25000,
        "total_credit": 25000,
        "est_equilibree": true,
        "saisie_par": { "id": 2, "nom": "Jean KABILA" },
        "date_soumission": "2024-03-15T10:30:00Z",
        "date_validation": null
      }
    ],
    "pagination": {
      "total": 248,
      "per_page": 20,
      "current_page": 1,
      "last_page": 13
    },
    "totaux": {
      "total_debit": 125000000,
      "total_credit": 125000000,
      "nb_ecritures": 248
    }
  }
}
```

---

### 2. POST `/ecritures`

**Description:** Créer une écriture comptable avec ses lignes

**URL:** `{{base_url}}/ecritures`

**Méthode:** `POST`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body (JSON) - Exemple recette consultation:**
```json
{
  "exercice_id": 1,
  "journal_id": 1,
  "date_ecriture": "2024-03-15",
  "libelle": "Consultation médecine interne - Patient MWAMBA",
  "reference": "CONS-2024-0145",
  "lignes": [
    {
      "compte_id": 10,
      "libelle": "Règlement consultation MWAMBA",
      "debit": 25000,
      "credit": 0,
      "devise": "CDF"
    },
    {
      "compte_id": 25,
      "libelle": "Produits consultations médicales",
      "debit": 0,
      "credit": 25000,
      "devise": "CDF"
    }
  ]
}
```

**Body (JSON) - Exemple achat médicaments:**
```json
{
  "exercice_id": 1,
  "journal_id": 2,
  "date_ecriture": "2024-03-15",
  "libelle": "Achat médicaments - Fournisseur PHARMAPLUS",
  "reference": "FAC-PHARM-2024-089",
  "lignes": [
    {
      "compte_id": 30,
      "libelle": "Achats médicaments",
      "debit": 150000,
      "credit": 0,
      "devise": "CDF"
    },
    {
      "compte_id": 40,
      "libelle": "Fournisseur PHARMAPLUS",
      "debit": 0,
      "credit": 150000,
      "devise": "CDF"
    }
  ]
}
```

**Body (JSON) - Écriture multi-lignes (répartition charges):**
```json
{
  "exercice_id": 1,
  "journal_id": 4,
  "date_ecriture": "2024-03-31",
  "libelle": "Répartition charges communes Mars 2024",
  "lignes": [
    { "compte_id": 50, "libelle": "Charges MED", "debit": 80000, "credit": 0, "devise": "CDF" },
    { "compte_id": 51, "libelle": "Charges PHARM", "debit": 40000, "credit": 0, "devise": "CDF" },
    { "compte_id": 52, "libelle": "Charges ADM", "debit": 30000, "credit": 0, "devise": "CDF" },
    { "compte_id": 20, "libelle": "Charges à répartir", "debit": 0, "credit": 150000, "devise": "CDF" }
  ]
}
```

**Réponse succès (201):**
```json
{
  "success": true,
  "message": "Écriture comptable créée avec succès",
  "data": {
    "id": 50,
    "numero": "JNL-VTE-2024-0050",
    "date_ecriture": "2024-03-15",
    "libelle": "Consultation médecine interne - Patient MWAMBA",
    "journal": { "id": 1, "nom": "Journal des Ventes" },
    "statut": "BROUILLON",
    "total_debit": 25000,
    "total_credit": 25000,
    "est_equilibree": true,
    "lignes": [
      { "id": 101, "compte_id": 10, "libelle": "Règlement consultation", "debit": 25000, "credit": 0 },
      { "id": 102, "compte_id": 25, "libelle": "Produits consultations", "debit": 0, "credit": 25000 }
    ],
    "created_at": "2024-03-15T10:00:00Z"
  }
}
```

**Erreur écriture déséquilibrée (422):**
```json
{
  "success": false,
  "message": "L'écriture comptable n'est pas équilibrée",
  "data": {
    "total_debit": 25000,
    "total_credit": 20000,
    "difference": 5000
  }
}
```

**Erreur exercice clôturé (400):**
```json
{
  "success": false,
  "message": "Impossible de créer une écriture: l'exercice 2023 est clôturé"
}
```

**Erreur lignes insuffisantes (422):**
```json
{
  "success": false,
  "message": "Une écriture comptable doit avoir au minimum 2 lignes"
}
```

---

### 3. GET `/ecritures/{id}`

**URL:** `{{base_url}}/ecritures/10`

**Méthode:** `GET`

**Headers:**
```
Authorization: Bearer {{access_token}}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "data": {
    "id": 10,
    "numero": "JNL-VTE-2024-0010",
    "date_ecriture": "2024-03-15",
    "libelle": "Consultation médecine interne - MWAMBA",
    "reference": "CONS-2024-0145",
    "journal": { "id": 1, "code": "JNL-VTE", "nom": "Journal des Ventes" },
    "exercice": { "id": 1, "annee": 2024 },
    "statut": "VALIDE",
    "total_debit": 25000,
    "total_credit": 25000,
    "est_equilibree": true,
    "lignes": [
      {
        "id": 21,
        "compte": { "id": 10, "code": "571000", "libelle": "Caisse principale" },
        "libelle": "Règlement consultation MWAMBA",
        "debit": 25000,
        "credit": 0,
        "devise": "CDF"
      },
      {
        "id": 22,
        "compte": { "id": 25, "code": "706000", "libelle": "Produits consultations" },
        "libelle": "Produits consultations médicales",
        "debit": 0,
        "credit": 25000,
        "devise": "CDF"
      }
    ],
    "historique": [
      { "action": "CREATION", "par": "Jean KABILA", "date": "2024-03-15T10:00:00Z", "commentaire": null },
      { "action": "SOUMISSION", "par": "Jean KABILA", "date": "2024-03-15T10:05:00Z", "commentaire": null },
      { "action": "VALIDATION", "par": "ADMIN Super", "date": "2024-03-15T11:00:00Z", "commentaire": "Conforme" }
    ],
    "saisie_par": { "id": 2, "nom": "Jean KABILA" },
    "valide_par": { "id": 1, "nom": "ADMIN Super" },
    "created_at": "2024-03-15T10:00:00Z",
    "updated_at": "2024-03-15T11:00:00Z"
  }
}
```

---

### 4. PUT `/ecritures/{id}/soumettre`

**Description:** Soumettre une écriture BROUILLON pour validation

**URL:** `{{base_url}}/ecritures/50/soumettre`

**Méthode:** `PUT`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body (JSON):**
```json
{
  "commentaire": "Écriture prête pour validation"
}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "message": "Écriture soumise pour validation",
  "data": {
    "id": 50,
    "statut": "SOUMIS",
    "date_soumission": "2024-03-15T10:30:00Z"
  }
}
```

**Erreur statut incorrect (400):**
```json
{
  "success": false,
  "message": "Seules les écritures en BROUILLON peuvent être soumises (statut actuel: VALIDE)"
}
```

---

### 5. PUT `/ecritures/{id}/valider`

**Description:** Valider une écriture soumise (rôle: Directeur/Admin)

**URL:** `{{base_url}}/ecritures/50/valider`

**Méthode:** `PUT`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body (JSON):**
```json
{
  "commentaire": "Écriture conforme, validée après vérification des justificatifs"
}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "message": "Écriture comptable validée avec succès",
  "data": {
    "id": 50,
    "statut": "VALIDE",
    "valide_par": "ADMIN Super",
    "date_validation": "2024-03-15T11:00:00Z"
  }
}
```

---

### 6. PUT `/ecritures/{id}/rejeter`

**URL:** `{{base_url}}/ecritures/50/rejeter`

**Méthode:** `PUT`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body (JSON):**
```json
{
  "commentaire": "Comptes incorrects, utiliser 706100 au lieu de 706000. Merci de corriger."
}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "message": "Écriture rejetée",
  "data": {
    "id": 50,
    "statut": "REJETE",
    "rejete_par": "ADMIN Super",
    "motif_rejet": "Comptes incorrects, utiliser 706100...",
    "date_rejet": "2024-03-15T11:00:00Z"
  }
}
```

---

## 📈 MODULE BUDGET

---

### 1. GET `/budgets`

**URL:** `{{base_url}}/budgets?exercice_id=1&service_id=2&statut=APPROUVE`

**Méthode:** `GET`

**Headers:**
```
Authorization: Bearer {{access_token}}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": 1,
        "titre": "Budget Comptabilité 2024",
        "exercice": { "id": 1, "annee": 2024 },
        "service": { "id": 2, "nom": "Comptabilité" },
        "montant_total": 2000000,
        "montant_consomme": 850000,
        "taux_execution": 42.5,
        "statut": "APPROUVE",
        "approuve_par": "ADMIN Super",
        "date_approbation": "2024-01-15"
      }
    ],
    "pagination": { "total": 8, "per_page": 20, "current_page": 1, "last_page": 1 }
  }
}
```

---

### 2. POST `/budgets`

**URL:** `{{base_url}}/budgets`

**Méthode:** `POST`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body (JSON):**
```json
{
  "titre": "Budget Médecine Interne 2024",
  "exercice_id": 1,
  "service_id": 3,
  "description": "Budget prévisionnel service médecine interne 2024",
  "lignes": [
    {
      "compte_id": 15,
      "libelle": "Charges de personnel médical",
      "montant_prevu": 5000000
    },
    {
      "compte_id": 30,
      "libelle": "Médicaments et consommables",
      "montant_prevu": 2000000
    },
    {
      "compte_id": 35,
      "libelle": "Matériel médical",
      "montant_prevu": 1000000
    }
  ]
}
```

**Réponse succès (201):**
```json
{
  "success": true,
  "message": "Budget créé avec succès",
  "data": {
    "id": 5,
    "titre": "Budget Médecine Interne 2024",
    "montant_total": 8000000,
    "statut": "BROUILLON",
    "created_at": "2024-03-15T10:00:00Z"
  }
}
```

---

### 3. GET `/budgets/execution`

**URL:** `{{base_url}}/budgets/execution?exercice_id=1&service_id=2`

**Méthode:** `GET`

**Headers:**
```
Authorization: Bearer {{access_token}}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "data": {
    "exercice": { "id": 1, "annee": 2024 },
    "service": { "id": 2, "nom": "Comptabilité" },
    "resume": {
      "montant_total_prevu": 2000000,
      "montant_total_realise": 850000,
      "ecart_global": 1150000,
      "taux_execution_global": 42.5
    },
    "detail_par_compte": [
      {
        "compte": { "id": 15, "code": "641000", "libelle": "Charges de personnel" },
        "montant_prevu": 1200000,
        "montant_realise": 600000,
        "ecart": 600000,
        "taux": 50.0,
        "statut_ecart": "NORMAL"
      },
      {
        "compte": { "id": 35, "code": "604100", "libelle": "Médicaments" },
        "montant_prevu": 200000,
        "montant_realise": 195000,
        "ecart": 5000,
        "taux": 97.5,
        "statut_ecart": "ALERTE"
      }
    ]
  }
}
```

---

## 💵 MODULE CAISSE

---

### 1. GET `/caisse/sessions`

**URL:** `{{base_url}}/caisse/sessions?page=1&statut=OUVERTE`

**Méthode:** `GET`

**Headers:**
```
Authorization: Bearer {{access_token}}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": 1,
        "reference": "SESS-2024-0025",
        "caissier": { "id": 5, "nom": "LUKUSA", "prenom": "Marie" },
        "date_ouverture": "2024-03-15T08:00:00Z",
        "date_fermeture": null,
        "solde_ouverture": 50000,
        "solde_theorique": 175000,
        "statut": "OUVERTE",
        "nb_transactions": 12,
        "total_entrees": 145000,
        "total_sorties": 20000
      }
    ],
    "pagination": { "total": 25, "per_page": 20, "current_page": 1, "last_page": 2 }
  }
}
```

---

### 2. POST `/caisse/ouvrir`

**URL:** `{{base_url}}/caisse/ouvrir`

**Méthode:** `POST`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body (JSON):**
```json
{
  "solde_ouverture": 50000,
  "devise": "CDF",
  "commentaire": "Ouverture caisse journée du 15/03/2024"
}
```

**Réponse succès (201):**
```json
{
  "success": true,
  "message": "Session de caisse ouverte avec succès",
  "data": {
    "id": 26,
    "reference": "SESS-2024-0026",
    "caissier": { "id": 5, "nom": "LUKUSA Marie" },
    "solde_ouverture": 50000,
    "devise": "CDF",
    "statut": "OUVERTE",
    "date_ouverture": "2024-03-15T08:00:00Z"
  }
}
```

**Erreur session déjà ouverte (400):**
```json
{
  "success": false,
  "message": "Vous avez déjà une session de caisse ouverte (SESS-2024-0025). Fermez-la avant d'en ouvrir une nouvelle."
}
```

---

### 3. POST `/caisse/transactions`

**URL:** `{{base_url}}/caisse/transactions`

**Méthode:** `POST`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body (JSON) - Encaissement:**
```json
{
  "session_id": 26,
  "type": "ENTREE",
  "montant": 25000,
  "devise": "CDF",
  "motif": "Consultation médecine interne - Patient MWAMBA",
  "beneficiaire": "MWAMBA Josephine",
  "reference_externe": "CONS-2024-0145",
  "compte_id": 25
}
```

**Body (JSON) - Décaissement:**
```json
{
  "session_id": 26,
  "type": "SORTIE",
  "montant": 8000,
  "devise": "CDF",
  "motif": "Achat fournitures de bureau",
  "beneficiaire": "Librairie MEDIATEX",
  "reference_externe": "TICK-20240315-001",
  "compte_id": 35
}
```

**Réponse succès (201):**
```json
{
  "success": true,
  "message": "Transaction enregistrée avec succès",
  "data": {
    "id": 89,
    "reference": "TXN-2024-0089",
    "type": "ENTREE",
    "montant": 25000,
    "devise": "CDF",
    "motif": "Consultation médecine interne - Patient MWAMBA",
    "solde_apres": 175000,
    "date_transaction": "2024-03-15T09:15:00Z"
  }
}
```

**Erreur solde insuffisant (400):**
```json
{
  "success": false,
  "message": "Solde insuffisant en caisse",
  "data": {
    "solde_disponible": 10000,
    "montant_demande": 25000
  }
}
```

---

### 4. PUT `/caisse/sessions/{id}/fermer`

**URL:** `{{base_url}}/caisse/sessions/26/fermer`

**Méthode:** `PUT`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body (JSON):**
```json
{
  "solde_reel": 174500,
  "commentaire": "Clôture caisse - écart de 500 CDF justifié par rendu monnaie"
}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "message": "Session de caisse fermée avec succès",
  "data": {
    "id": 26,
    "statut": "FERMEE",
    "solde_ouverture": 50000,
    "total_entrees": 145000,
    "total_sorties": 20000,
    "solde_theorique": 175000,
    "solde_reel": 174500,
    "ecart": -500,
    "date_fermeture": "2024-03-15T17:00:00Z"
  }
}
```

---

### 5. GET `/caisse/sessions/{id}/rapport`

**URL:** `{{base_url}}/caisse/sessions/26/rapport`

**Méthode:** `GET`

**Headers:**
```
Authorization: Bearer {{access_token}}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "data": {
    "session": {
      "id": 26,
      "reference": "SESS-2024-0026",
      "caissier": "LUKUSA Marie",
      "date": "2024-03-15",
      "statut": "FERMEE"
    },
    "resume": {
      "solde_ouverture": 50000,
      "total_entrees": 145000,
      "total_sorties": 20000,
      "solde_theorique": 175000,
      "solde_reel": 174500,
      "ecart": -500,
      "nb_transactions": 12
    },
    "transactions": [
      {
        "heure": "09:15",
        "type": "ENTREE",
        "montant": 25000,
        "motif": "Consultation médecine interne - MWAMBA",
        "reference": "TXN-2024-0089"
      }
    ],
    "repartition_par_type": {
      "consultations": 85000,
      "hospitalisations": 45000,
      "pharmacie": 15000,
      "sorties_diverses": 20000
    }
  }
}
```

---

## 📊 MODULE RAPPORTS

---

### 1. GET `/rapports/dashboard`

**URL:** `{{base_url}}/rapports/dashboard?exercice_id=1`

**Méthode:** `GET`

**Headers:**
```
Authorization: Bearer {{access_token}}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "data": {
    "exercice": { "id": 1, "annee": 2024 },
    "kpi": {
      "total_recettes": 125000000,
      "total_depenses": 98000000,
      "resultat_net": 27000000,
      "taux_execution_budget": 65.3,
      "nb_ecritures_en_attente": 12,
      "solde_caisse": 175000,
      "solde_banque": 4500000
    },
    "evolution_mensuelle": [
      { "mois": "Janvier", "recettes": 9500000, "depenses": 7800000 },
      { "mois": "Février", "recettes": 10200000, "depenses": 8100000 },
      { "mois": "Mars", "recettes": 11000000, "depenses": 8500000 }
    ],
    "top_comptes_charges": [
      { "compte": "Charges de personnel", "montant": 45000000, "pourcentage": 45.9 },
      { "compte": "Médicaments", "montant": 20000000, "pourcentage": 20.4 }
    ],
    "alertes": [
      {
        "type": "BUDGET_DEPASSE",
        "service": "Pharmacie",
        "message": "Budget médicaments dépassé à 97.5%"
      },
      {
        "type": "ECRITURES_EN_ATTENTE",
        "message": "12 écritures en attente de validation depuis plus de 48h"
      }
    ]
  }
}
```

---

### 2. GET `/rapports/grand-livre`

**URL:** `{{base_url}}/rapports/grand-livre?compte_id=10&date_debut=2024-01-01&date_fin=2024-03-31`

**Méthode:** `GET`

**Query Parameters:**

| Paramètre | Requis | Description |
|-----------|--------|-------------|
| `compte_id` | Oui | ID du compte |
| `date_debut` | Oui | Date début |
| `date_fin` | Oui | Date fin |
| `exercice_id` | Non | Exercice fiscal |

**Réponse succès (200):**
```json
{
  "success": true,
  "data": {
    "compte": { "id": 10, "code": "571000", "libelle": "Caisse principale" },
    "periode": { "debut": "2024-01-01", "fin": "2024-03-31" },
    "solde_initial": 50000,
    "mouvements": [
      {
        "date": "2024-03-15",
        "numero_ecriture": "JNL-VTE-2024-0010",
        "libelle": "Consultation MWAMBA",
        "debit": 25000,
        "credit": 0,
        "solde_cumule": 175000
      },
      {
        "date": "2024-03-15",
        "numero_ecriture": "JNL-CAI-2024-0089",
        "libelle": "Achat fournitures",
        "debit": 0,
        "credit": 8000,
        "solde_cumule": 167000
      }
    ],
    "totaux": {
      "total_debit": 145000,
      "total_credit": 28000,
      "solde_final": 167000
    },
    "nb_mouvements": 58
  }
}
```

---

### 3. GET `/rapports/balance`

**URL:** `{{base_url}}/rapports/balance?exercice_id=1`

**Méthode:** `GET`

**Headers:**
```
Authorization: Bearer {{access_token}}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "data": {
    "exercice": { "id": 1, "annee": 2024 },
    "date_generation": "2024-03-15",
    "comptes": [
      {
        "code": "571000",
        "libelle": "Caisse principale",
        "solde_initial_debit": 50000,
        "solde_initial_credit": 0,
        "mouvements_debit": 145000,
        "mouvements_credit": 28000,
        "solde_final_debit": 167000,
        "solde_final_credit": 0
      },
      {
        "code": "706000",
        "libelle": "Produits consultations",
        "solde_initial_debit": 0,
        "solde_initial_credit": 0,
        "mouvements_debit": 0,
        "mouvements_credit": 85000,
        "solde_final_debit": 0,
        "solde_final_credit": 85000
      }
    ],
    "verification": {
      "total_debit": 125000000,
      "total_credit": 125000000,
      "est_equilibree": true
    }
  }
}
```

---

## 🏦 MODULE TRESORERIE

---

### 1. POST `/tresorerie/mouvements`

**URL:** `{{base_url}}/tresorerie/mouvements`

**Méthode:** `POST`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body (JSON):**
```json
{
  "compte_tresorerie_id": 1,
  "type": "CREDIT",
  "montant": 500000,
  "devise": "CDF",
  "date_valeur": "2024-03-15",
  "libelle": "Virement reçu - Subvention Ministère Santé",
  "reference_bancaire": "VIR-BNK-2024-0456",
  "compte_comptable_id": 15
}
```

**Réponse succès (201):**
```json
{
  "success": true,
  "message": "Mouvement de trésorerie enregistré",
  "data": {
    "id": 78,
    "type": "CREDIT",
    "montant": 500000,
    "solde_apres": 4500000,
    "date_valeur": "2024-03-15",
    "reference": "MVT-2024-0078"
  }
}
```

---

### 2. POST `/tresorerie/rapprochement`

**URL:** `{{base_url}}/tresorerie/rapprochement`

**Méthode:** `POST`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body (JSON):**
```json
{
  "compte_tresorerie_id": 1,
  "date_releve": "2024-03-31",
  "solde_releve_bancaire": 4850000,
  "mouvements_a_pointer": [78, 79, 80, 81]
}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "message": "Rapprochement bancaire effectué",
  "data": {
    "solde_comptable": 4500000,
    "solde_bancaire": 4850000,
    "ecart": 350000,
    "mouvements_pointes": 4,
    "mouvements_non_pointes": 2,
    "statut": "ECART_IDENTIFIE"
  }
}
```

---

## 📦 MODULE STOCK

---

### 1. POST `/stock/produits`

**URL:** `{{base_url}}/stock/produits`

**Méthode:** `POST`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body (JSON):**
```json
{
  "code": "MED-AMOX-500",
  "nom": "Amoxicilline 500mg",
  "description": "Antibiotique - boîte de 16 gélules",
  "categorie_id": 1,
  "unite": "BOITE",
  "prix_unitaire": 3500,
  "stock_actuel": 150,
  "stock_minimum": 20,
  "stock_maximum": 500,
  "compte_comptable_id": 30
}
```

**Réponse succès (201):**
```json
{
  "success": true,
  "message": "Produit créé avec succès",
  "data": {
    "id": 25,
    "code": "MED-AMOX-500",
    "nom": "Amoxicilline 500mg",
    "stock_actuel": 150,
    "valeur_stock": 525000,
    "statut_stock": "NORMAL",
    "created_at": "2024-03-15T10:00:00Z"
  }
}
```

---

### 2. POST `/stock/mouvements`

**URL:** `{{base_url}}/stock/mouvements`

**Méthode:** `POST`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body (JSON) - Entrée stock:**
```json
{
  "produit_id": 25,
  "type": "ENTREE",
  "quantite": 100,
  "prix_unitaire": 3500,
  "motif": "Réapprovisionnement mensuel",
  "reference": "BON-REC-2024-025",
  "fournisseur_id": 3,
  "date_expiration": "2025-06-30"
}
```

**Body (JSON) - Sortie stock:**
```json
{
  "produit_id": 25,
  "type": "SORTIE",
  "quantite": 10,
  "motif": "Dispensation patient - Médecine Interne",
  "reference": "ORD-MED-2024-456",
  "service_id": 3
}
```

**Réponse succès (201):**
```json
{
  "success": true,
  "message": "Mouvement de stock enregistré",
  "data": {
    "id": 156,
    "type": "ENTREE",
    "quantite": 100,
    "stock_avant": 150,
    "stock_apres": 250,
    "produit": "Amoxicilline 500mg",
    "date": "2024-03-15T10:00:00Z"
  }
}
```

**Erreur stock insuffisant (400):**
```json
{
  "success": false,
  "message": "Stock insuffisant pour ce mouvement",
  "data": {
    "stock_disponible": 5,
    "quantite_demandee": 10
  }
}
```

---

### 3. GET `/stock/produits/alertes`

**URL:** `{{base_url}}/stock/produits/alertes`

**Méthode:** `GET`

**Headers:**
```
Authorization: Bearer {{access_token}}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "data": {
    "total_alertes": 5,
    "ruptures": [
      { "id": 12, "code": "MED-PEN-V", "nom": "Pénicilline V", "stock_actuel": 0, "stock_minimum": 10 }
    ],
    "stock_faible": [
      { "id": 15, "code": "MED-MET-250", "nom": "Métronidazole 250mg", "stock_actuel": 8, "stock_minimum": 20 }
    ],
    "expires_bientot": [
      { "id": 25, "nom": "Amoxicilline 500mg", "quantite": 30, "date_expiration": "2024-04-15", "jours_restants": 31 }
    ]
  }
}
```

---

## 🧾 MODULE FACTURES

---

### 1. POST `/factures`

**URL:** `{{base_url}}/factures`

**Méthode:** `POST`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body (JSON) - Facture client:**
```json
{
  "type": "CLIENT",
  "client_nom": "MWAMBA Josephine",
  "client_telephone": "+243812345678",
  "date_facture": "2024-03-15",
  "date_echeance": "2024-03-15",
  "exercice_id": 1,
  "lignes": [
    {
      "description": "Consultation médecine interne",
      "quantite": 1,
      "prix_unitaire": 15000,
      "compte_produit_id": 25
    },
    {
      "description": "Médicaments prescrits",
      "quantite": 2,
      "prix_unitaire": 5000,
      "compte_produit_id": 26
    }
  ],
  "remise": 0,
  "notes": "Prise en charge partielle mutuelle"
}
```

**Body (JSON) - Facture fournisseur:**
```json
{
  "type": "FOURNISSEUR",
  "fournisseur_id": 3,
  "date_facture": "2024-03-15",
  "date_echeance": "2024-04-15",
  "reference_fournisseur": "FAC-PHARM-2024-089",
  "exercice_id": 1,
  "lignes": [
    {
      "description": "Amoxicilline 500mg - 100 boîtes",
      "quantite": 100,
      "prix_unitaire": 3500,
      "compte_charge_id": 30
    }
  ]
}
```

**Réponse succès (201):**
```json
{
  "success": true,
  "message": "Facture créée avec succès",
  "data": {
    "id": 88,
    "numero": "FAC-2024-0088",
    "type": "CLIENT",
    "montant_ht": 25000,
    "montant_tva": 0,
    "montant_ttc": 25000,
    "statut": "EMISE",
    "date_facture": "2024-03-15",
    "date_echeance": "2024-03-15",
    "created_at": "2024-03-15T10:00:00Z"
  }
}
```

---

### 2. POST `/factures/{id}/paiement`

**URL:** `{{base_url}}/factures/88/paiement`

**Méthode:** `POST`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body (JSON):**
```json
{
  "montant": 25000,
  "mode_paiement": "ESPECES",
  "date_paiement": "2024-03-15",
  "reference_paiement": "REÇ-2024-0088",
  "compte_tresorerie_id": 1,
  "commentaire": "Paiement intégral en espèces"
}
```

**Réponse succès (200):**
```json
{
  "success": true,
  "message": "Paiement enregistré avec succès",
  "data": {
    "facture_id": 88,
    "statut": "PAYEE",
    "montant_paye": 25000,
    "montant_restant": 0,
    "date_paiement": "2024-03-15"
  }
}
```

---

## 👨‍💼 MODULE EMPLOYES

---

### 1. POST `/employes`

**URL:** `{{base_url}}/employes`

**Méthode:** `POST`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body (JSON):**
```json
{
  "matricule": "EMP-MED-015",
  "nom": "TSHIMANGA",
  "prenom": "Docteur Paul",
  "email": "paul.tshimanga@hopital-nk.cd",
  "telephone": "+243891234567",
  "date_naissance": "1980-05-15",
  "date_embauche": "2015-03-01",
  "service_id": 3,
  "poste": "Médecin Interniste",
  "type_contrat": "CDI",
  "salaire_base": 850000,
  "devise_salaire": "CDF",
  "numero_cnss": "CNSS-123456789",
  "statut": "ACTIF"
}
```

**Réponse succès (201):**
```json
{
  "success": true,
  "message": "Employé créé avec succès",
  "data": {
    "id": 35,
    "matricule": "EMP-MED-015",
    "nom": "TSHIMANGA",
    "prenom": "Docteur Paul",
    "service": { "id": 3, "nom": "Médecine Interne" },
    "statut": "ACTIF",
    "created_at": "2024-03-15T10:00:00Z"
  }
}
```

---

## 💸 MODULE SALAIRES

---

### 1. POST `/salaires/bulletins`

**URL:** `{{base_url}}/salaires/bulletins`

**Méthode:** `POST`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {{access_token}}
```

**Body (JSON):**
```json
{
  "employe_id": 35,
  "mois": 3,
  "annee": 2024,
  "salaire_base": 850000,
  "primes": [
    { "libelle": "Prime de risque", "montant": 100000 },
    { "libelle": "Prime de transport", "montant": 50000 }
  ],
  "deductions": [
    { "libelle": "CNSS employé (3.5%)", "montant": 29750 },
    { "libelle": "IPR (Impôt professionnel)", "montant": 75000 }
  ],
  "exercice_id": 1
}
```

**Réponse succès (201):**
```json
{
  "success": true,
  "message": "Bulletin de salaire créé avec succès",
  "data": {
    "id": 45,
    "employe": { "id": 35, "nom": "TSHIMANGA Paul", "matricule": "EMP-MED-015" },
    "periode": "Mars 2024",
    "salaire_brut": 1000000,
    "total_deductions": 104750,
    "salaire_net": 895250,
    "statut": "BROUILLON",
    "created_at": "2024-03-15T10:00:00Z"
  }
}
```

---

## ⚠️ CODES D'ERREUR - DÉTAIL COMPLET

| Code HTTP | Signification | Cause typique |
|-----------|---------------|---------------|
| `200` | Succès | Opération réussie |
| `201` | Créé | Ressource créée |
| `400` | Requête invalide | Logique métier violée |
| `401` | Non authentifié | Token absent/expiré |
| `403` | Accès refusé | Permission insuffisante |
| `404` | Non trouvé | Ressource inexistante |
| `422` | Validation échouée | Données invalides/manquantes |
| `423` | Compte verrouillé | Trop de tentatives login |
| `500` | Erreur serveur | Bug PHP/MySQL |

---

## ✅ CHECKLIST DE TEST POSTMAN - ORDRE RECOMMANDÉ

```
ÉTAPE 1 - AUTH
  □ POST /auth/login          → Récupérer access_token
  □ GET  /auth/me             → Vérifier profil
  □ POST /auth/refresh        → Renouveler token
  
ÉTAPE 2 - RÉFÉRENTIELS
  □ GET  /roles               → Lister rôles
  □ GET  /roles/permissions   → Voir toutes les permissions
  □ GET  /services            → Lister services
  □ GET  /exercices/current   → Exercice courant
  □ GET  /journaux            → Lister journaux
  □ GET  /plan-comptable      → Comptes disponibles

ÉTAPE 3 - UTILISATEURS
  □ POST /users               → Créer utilisateur
  □ GET  /users               → Lister
  □ PUT  /users/{id}          → Modifier
  
ÉTAPE 4 - ÉCRITURES COMPTABLES
  □ POST /ecritures           → Créer (statut: BROUILLON)
  □ PUT  /ecritures/{id}/soumettre → Soumettre
  □ PUT  /ecritures/{id}/valider   → Valider (admin)
  □ GET  /ecritures/{id}      → Vérifier historique

ÉTAPE 5 - CAISSE
  □ POST /caisse/ouvrir       → Ouvrir session
  □ POST /caisse/transactions → Encaisser (ENTREE)
  □ POST /caisse/transactions → Décaisser (SORTIE)
  □ GET  /caisse/sessions/{id}/rapport → Rapport
  □ PUT  /caisse/sessions/{id}/fermer  → Fermer

ÉTAPE 6 - BUDGET
  □ POST /budgets             → Créer budget
  □ PUT  /budgets/{id}/soumettre → Soumettre
  □ PUT  /budgets/{id}/approuver → Approuver

ÉTAPE 7 - STOCK
  □ POST /stock/produits      → Créer produit
  □ POST /stock/mouvements    → Entrée stock
  □ GET  /stock/produits/alertes → Alertes

ÉTAPE 8 - RAPPORTS
  □ GET /rapports/dashboard   → Vue globale
  □ GET /rapports/balance     → Balance comptable
  □ GET /rapports/grand-livre?compte_id=10&date_debut=2024-01-01&date_fin=2024-12-31
```