# Metabase - Business Intelligence & Analytics Platform

## 📊 Overview

Metabase is a powerful, open-source business intelligence platform that enables data-driven decision making across Vita Strategies. This enterprise deployment provides interactive dashboards, automated reporting, and self-service analytics for all business stakeholders.

## 🚀 Features

### Core Analytics Capabilities
- **Interactive Dashboards** - Real-time business metrics and KPIs
- **Question Builder** - Intuitive query interface for non-technical users
- **SQL Editor** - Advanced querying capabilities for power users
- **Data Visualization** - Charts, graphs, maps, and custom visualizations
- **Automated Reports** - Scheduled email reports and alerts
- **Data Exploration** - Self-service analytics and ad-hoc queries
- **Mobile Access** - Responsive design for mobile analytics
- **Embedding** - White-label dashboard embedding in applications

### Advanced Features
- **Data Modeling** - Custom fields, segments, and metrics
- **Collections** - Organized dashboard and question libraries
- **Permissions** - Granular data access controls
- **Caching** - Query result caching for performance
- **API Access** - RESTful API for programmatic access
- **Slack Integration** - Dashboard notifications and queries
- **SSO Integration** - Keycloak authentication integration
- **Multi-database** - Connect multiple data sources

### Business Intelligence Tools
- **Executive Dashboards** - C-level metrics and strategic KPIs
- **Sales Analytics** - Revenue tracking and sales performance
- **Financial Reporting** - P&L, cash flow, and financial metrics
- **Operational Metrics** - Process efficiency and performance
- **Customer Analytics** - Customer behavior and satisfaction
- **Marketing Analytics** - Campaign performance and ROI
- **HR Analytics** - Employee metrics and workforce insights
- **Product Analytics** - Usage statistics and feature adoption

## 🔧 Technical Architecture

### Container Configuration
- **Base:** Official Metabase image with production optimizations
- **Database:** PostgreSQL for application data storage
- **Data Sources:** Multi-database connectivity (PostgreSQL, MySQL, MariaDB)
- **Cache:** Redis for query result caching
- **Storage:** GCS integration for dashboard exports
- **Authentication:** Keycloak SSO integration

### Security Features
- **HTTPS Enforcement** - SSL/TLS encryption for all communications
- **SSO Authentication** - Keycloak integration for unified login
- **Role-based Access** - Granular permissions for data access
- **Data Security** - Row-level security and column permissions
- **Audit Logging** - User activity and data access tracking
- **Session Management** - Secure session handling
- **CSRF Protection** - Cross-site request forgery prevention
- **SQL Injection Prevention** - Parameterized query protection

### Performance Optimizations
- **Query Caching** - Intelligent result caching for faster load times
- **Database Indexing** - Optimized indexes for analytical queries
- **Connection Pooling** - Efficient database connection management
- **CDN Integration** - Static asset delivery optimization
- **Async Processing** - Background job processing for large queries
- **Memory Management** - JVM tuning for analytical workloads

## 🌐 Integration Points

### Data Source Connections
- **ERPNext Database** - Business operations and financial data
- **WordPress Database** - Website analytics and content metrics
- **Mattermost Database** - Team collaboration analytics
- **Google Analytics** - Website traffic and user behavior
- **Stripe/Payment Data** - Revenue and transaction analytics
- **Custom APIs** - External data source integration

### Application Integration
- **Keycloak** - Single sign-on authentication
- **OpenBao** - Database credentials management
- **Grafana** - Infrastructure metrics correlation
- **Slack** - Automated report delivery
- **Email** - Scheduled report distribution
- **Webhook Integration** - Real-time data updates

### Export and Sharing
- **PDF Reports** - Automated PDF generation
- **Excel Exports** - Data export for offline analysis
- **CSV Downloads** - Raw data extraction
- **Dashboard Embedding** - Iframe embedding in applications
- **Public Links** - Shareable dashboard URLs
- **API Access** - Programmatic data retrieval

## 📈 Dashboard Examples

### Executive Dashboard
- **Revenue Metrics** - Monthly/quarterly revenue trends
- **Customer Acquisition** - New customer growth rates
- **Operational Efficiency** - Key performance indicators
- **Financial Health** - Cash flow and profitability metrics
- **Market Performance** - Competitive analysis metrics

### Sales Dashboard
- **Sales Pipeline** - Opportunity tracking and conversion rates
- **Revenue Forecasting** - Predictive sales analytics
- **Team Performance** - Individual and team metrics
- **Customer Segmentation** - Customer value analysis
- **Product Performance** - Top-selling products and services

### Operations Dashboard
- **Process Metrics** - Operational efficiency indicators
- **Quality Metrics** - Error rates and quality scores
- **Resource Utilization** - Capacity and utilization tracking
- **Cost Analysis** - Operational cost breakdowns
- **Productivity Metrics** - Employee and process productivity

## 🛡️ Security Configuration

### Authentication & Authorization
- **Keycloak SSO** - Centralized authentication management
- **Role-based Permissions** - Data access control by user role
- **Group Permissions** - Team-based access management
- **Database Permissions** - Table and column-level access
- **Collection Security** - Dashboard and question permissions
- **Public Sharing Controls** - Restricted public access

### Data Protection
- **Encryption at Rest** - Database encryption for sensitive data
- **Encryption in Transit** - HTTPS for all communications
- **Data Masking** - Sensitive data protection in reports
- **Query Logging** - Audit trail for data access
- **IP Restrictions** - Network-based access controls
- **Session Security** - Secure session management

### Compliance Features
- **GDPR Compliance** - Data protection and privacy controls
- **SOC 2 Ready** - Security and availability controls
- **Audit Logging** - Comprehensive activity tracking
- **Data Retention** - Configurable data retention policies
- **Access Reviews** - Regular permission audits
- **Security Monitoring** - Real-time security alerts

## 📊 Analytics Capabilities

### Data Visualization Types
- **Line Charts** - Trend analysis and time series data
- **Bar Charts** - Categorical data comparison
- **Pie Charts** - Composition and percentage breakdowns
- **Scatter Plots** - Correlation and relationship analysis
- **Heatmaps** - Pattern recognition and density analysis
- **Geographic Maps** - Location-based analytics
- **Funnel Charts** - Conversion and process analysis
- **Gauge Charts** - KPI and performance indicators

### Statistical Functions
- **Aggregations** - Sum, average, count, min, max
- **Percentiles** - Distribution analysis
- **Moving Averages** - Trend smoothing
- **Growth Rates** - Period-over-period comparisons
- **Cohort Analysis** - Customer behavior tracking
- **Forecasting** - Predictive analytics capabilities
- **Regression Analysis** - Correlation and prediction
- **Statistical Tests** - Significance testing

### Advanced Analytics
- **Custom Metrics** - Calculated fields and formulas
- **Segments** - Dynamic user and data segmentation
- **Filters** - Interactive dashboard filtering
- **Drill-down** - Hierarchical data exploration
- **Time Intelligence** - Date-based calculations
- **Cross-filtering** - Dashboard interactivity
- **Alerting** - Automated threshold notifications
- **Anomaly Detection** - Unusual pattern identification

## 📡 API Documentation

### REST API Endpoints
```bash
# Get dashboard list
GET /api/dashboard
Authorization: Bearer {api-token}

# Get dashboard data
GET /api/dashboard/{dashboard-id}
Authorization: Bearer {api-token}

# Execute query
POST /api/dataset
Content-Type: application/json
{
  "database": 1,
  "query": {
    "source-table": 1,
    "aggregation": [["count"]]
  }
}

# Get user permissions
GET /api/user/current
Authorization: Bearer {api-token}
```

### Webhook Integration
```bash
# Webhook for real-time updates
POST /api/webhook/data-update
Content-Type: application/json
{
  "source": "erp",
  "table": "sales_orders",
  "action": "insert",
  "data": {...}
}
```

### Embedding API
```html
<!-- Dashboard embedding -->
<iframe
  src="https://analytics.vitastrategies.com/embed/dashboard/{token}#bordered=true&titled=true"
  frameborder="0"
  width="800"
  height="600"
  allowtransparency>
</iframe>
```

## ⚙️ Configuration Management

### Database Connections
- **Primary Database** - PostgreSQL for Metabase application data
- **ERPNext Connection** - MariaDB for business operations data
- **WordPress Connection** - MySQL for website analytics
- **Analytics Database** - Dedicated PostgreSQL for data warehouse

### Authentication Configuration
- **Keycloak Integration** - SAML/OIDC authentication setup
- **User Synchronization** - Automated user provisioning
- **Group Mapping** - Role-based access assignment
- **Session Management** - Timeout and security settings

### Performance Settings
- **Query Caching** - Result caching configuration
- **Connection Pooling** - Database connection limits
- **Memory Allocation** - JVM heap size optimization
- **Background Jobs** - Scheduled task configuration

## 🔧 Environment Variables

### Core Configuration
```bash
# Database configuration
MB_DB_TYPE=postgres
MB_DB_DBNAME=metabase
MB_DB_PORT=5432
MB_DB_USER=metabase_user
MB_DB_PASS=${METABASE_DB_PASSWORD}
MB_DB_HOST=postgres

# Application settings
MB_SITE_NAME="Vita Strategies Analytics"
MB_SITE_URL=https://analytics.vitastrategies.com
MB_ADMIN_EMAIL=${METABASE_ADMIN_EMAIL}

# Security settings
MB_ENCRYPTION_SECRET_KEY=${METABASE_ENCRYPTION_KEY}
MB_SESSION_COOKIES=true
MB_SITE_LOCALE=en
MB_ANON_TRACKING_ENABLED=false

# Performance settings
JAVA_OPTS="-Xmx2g -Xms1g"
MB_JETTY_PORT=3000
MB_JETTY_HOST=0.0.0.0
```

### Integration Settings
```bash
# Keycloak SSO
MB_SAML_ENABLED=true
MB_SAML_IDENTITY_PROVIDER_URI=https://auth.vitastrategies.com/realms/vita-strategies/protocol/saml/descriptor
MB_SAML_APPLICATION_NAME="Metabase Analytics"

# Email configuration
MB_EMAIL_SMTP_HOST=smtp.gmail.com
MB_EMAIL_SMTP_PORT=587
MB_EMAIL_SMTP_SECURITY=tls
MB_EMAIL_SMTP_USERNAME=${SMTP_USERNAME}
MB_EMAIL_SMTP_PASSWORD=${SMTP_PASSWORD}

# Slack integration
MB_SLACK_TOKEN=${SLACK_BOT_TOKEN}
MB_SLACK_CHANNEL=#analytics
```

## 📦 Docker Deployment

### Quick Start
```bash
# Clone and setup
git clone https://github.com/vita-strategies/metabase.git
cd metabase

# Configure environment
cp .env.example .env
# Edit .env with your configuration

# Start services
docker-compose up -d

# Check health
curl https://analytics.vitastrategies.com/api/health
```

### Production Deployment
```bash
# Build production image
docker-compose -f docker-compose.yml -f docker-compose.prod.yml build

# Deploy with monitoring
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Setup initial admin
docker-compose exec metabase java -jar metabase.jar --setup
```

## 🛠️ Maintenance & Operations

### Backup Procedures
```bash
# Database backup
docker-compose exec postgres pg_dump -U metabase_user metabase > metabase-backup.sql

# Application settings backup
docker-compose exec metabase curl -H "X-Metabase-Session: {token}" \
  http://localhost:3000/api/setting > settings-backup.json

# Dashboard exports
docker-compose exec metabase java -jar metabase.jar export-dashboards
```

### Performance Monitoring
```bash
# Check query performance
curl -H "X-Metabase-Session: {token}" \
  https://analytics.vitastrategies.com/api/util/stats

# Monitor resource usage
docker stats metabase-server

# Check database connections
docker-compose exec metabase netstat -an | grep 5432
```

### Troubleshooting
```bash
# Check logs
docker-compose logs -f metabase

# Database connectivity test
docker-compose exec metabase nc -z postgres 5432

# Memory usage check
docker-compose exec metabase java -XX:+PrintFlagsFinal -version | grep HeapSize
```

## 📱 Mobile & Responsive Design

### Mobile Features
- **Responsive Dashboards** - Optimized for mobile devices
- **Touch Interactions** - Gesture-based navigation
- **Offline Viewing** - Cached dashboard access
- **Mobile Notifications** - Alert delivery to mobile devices
- **Quick Actions** - One-tap common operations

### Progressive Web App
- **PWA Support** - Install as mobile app
- **Push Notifications** - Real-time alert delivery
- **Offline Capabilities** - Limited offline functionality
- **App-like Experience** - Native mobile app feel

## 🔗 External Links

- **Official Documentation:** https://www.metabase.com/docs/
- **Admin Guide:** https://www.metabase.com/docs/latest/administration-guide/
- **API Documentation:** https://www.metabase.com/docs/latest/api-documentation
- **Community Forum:** https://discourse.metabase.com/
- **GitHub Repository:** https://github.com/metabase/metabase

---

**🏢 Vita Strategies - Business Intelligence & Analytics Platform**  
For support and questions: admin@vitastrategies.com
