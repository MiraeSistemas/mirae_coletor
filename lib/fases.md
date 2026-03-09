Fase 1 — Base (agora)

Estrutura de pastas e arquitetura
DatabaseHelper + migrations
ApiClient com Dio + interceptors
ConnectivityService
SyncManager + SyncQueue
Repositório base (local + remoto)

Fase 2 — Funcionalidades

Entidades e tabelas do domínio do negócio
Telas e fluxos do app
Design system e UI

Fase 3 — Qualidade

Testes unitários (domínio e repositórios)
Testes de widget
Testes de integração
CI/CD (GitHub Actions ou Codemagic)

Fase 4 — Preparação para Publicação
Android (Play Store)

Gerar keystore de assinatura e guardar em local seguro
Configurar build.gradle com applicationId, versão e signing config
Gerar App Bundle (.aab) — formato exigido pelo Google
Criar conta no Google Play Console (~$25 taxa única)
Preencher ficha do app: descrição, screenshots, política de privacidade
Passar pela revisão (normalmente 1-3 dias)

iOS (App Store)

Necessário Mac ou serviço como Codemagic para o build
Conta Apple Developer (~$99/ano)
Criar App ID, Provisioning Profile e Certificado no Apple Developer Portal
Configurar Bundle Identifier no Xcode
Gerar .ipa via flutter build ipa
Enviar via Xcode ou Transporter
Preencher ficha no App Store Connect: descrição, screenshots (tamanhos específicos por device), política de privacidade (obrigatória)
Revisão da Apple é mais rigorosa, pode levar de 1 dia a 1 semana

Itens obrigatórios para ambas as lojas

Política de Privacidade (URL pública) — obrigatória se coletar qualquer dado
Ícone do app em múltiplas resoluções
Screenshots de dispositivos específicos
Descrição e metadados do app

Fase 5 — Pós-publicação

Monitoramento de erros: Firebase Crashlytics
Analytics: Firebase Analytics ou similar
Sistema de atualização forçada (verificar versão mínima na API)
Push notifications: Firebase Cloud Messaging (FCM)
