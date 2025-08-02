# 📁 VITA STRATEGIES - CLEAN PROJECT STRUCTURE

```
vita-strategies/
├── README.md                           # Main documentation
├── CREDENTIALS.md                      # Login details
├── docker-compose-persistent.yml      # Production services
├── .env.example                       # Environment template
├── .gitignore                         # Git ignore rules
│
├── environments/                      # Environment configs
│   ├── development/
│   ├── staging/
│   └── production/
│
├── infrastructure/                    # Infrastructure as Code
│   ├── terraform/
│   │   └── complete-infrastructure.tf
│   └── startup-scripts/
│       └── startup-script-with-buckets.sh
│
└── scripts/                          # Deployment tools
    ├── deploy-complete.sh             # Main deployment
    ├── bucket-manager.sh              # Data management
    └── validate-architecture.sh      # Validation
```

## 🚀 USAGE

**Deploy:** `./scripts/deploy-complete.sh production`
**Manage Data:** `./scripts/bucket-manager.sh`
**Validate:** `./scripts/validate-architecture.sh`

## 🎯 WHAT'S INCLUDED

✅ **8 Enterprise Services** (ERPNext, Metabase, Grafana, etc.)
✅ **Google Cloud Storage** (5 specialized buckets)
✅ **Terraform Infrastructure** (Professional IaC)
✅ **Docker Compose** (Container orchestration)
✅ **Environment Management** (dev/staging/prod)
✅ **Automated Backups** (Every 4 hours)
✅ **Easy Data Access** (GUI + CLI tools)

**Everything you need. Nothing you don't.**
