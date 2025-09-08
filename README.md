# Processo de Criação de Novos Repositórios

## 1. Rodar a Action
- Rodar a action em [Zoop Template Actions](https://github.com/getzoop/zoop-template/actions).
- O nome não precisa conter 'zoop', pois a action já ajusta automaticamente.

## 2. Conceder as permissões no repo
- Ir na aba administrativa e liberar o permissionamento de escrita para quem abriu e os respectivos grupos que ele.

## 3. Ajustar o Repositório Criado
- Ajustar o arquivo `CODEOWNERS`, colocando o nome do grupo de quem solicitou em primeiro lugar.
- Limpar o conteúdo do arquivo `README.md`.

## 4. Ajustar a Action `run_security_check`
- Alterar a linguagem do projeto no arquivo `.github/workflows`.
  - Essa informação deve ser fornecida pelo solicitante.
  - Caso a linguagem seja Go, incluir o campo `go-version` abaixo de `language`. Essa informação também deve ser fornecida pelo solicitante.
  - 

## 5. Mudar Variavel no .gitlab-ci e repository-metadata.yaml para o nome do projeto
## No arquivo repository-metadata.yaml: 
    - preenchimento dos campos slug, nome da aplicação e impactLevel. 
    - campo name deve refletir o nome real do serviço.
    - ownerLayerSlug deve estar correto e atualizado.
    - impactLevel deve ser preenchido adequadamente de acordo com a criticidade do serviço.

Doc apoio: https://ifood.atlassian.net/wiki/spaces/EN/pages/1331003434/IRC-MTDT+v2.2.0+Metadata+Standard
- validar se o campo **ownerLayerSlug** existe no Tompero (https://tompero.ifoodcorp.com.br/tech-organization) antes de criar
  

## 6. Aplicar Bloqueios de Branch
- Antes de tudo, executar o Workflow de Dependabot Security Check na branch default para que seja liberado na configuração do bloqueio de branch;
- Navegar para: `Settings -> Branches`.
- Clicar em "Add classic branch protection rule"
- Configurar os bloqueios de branch conforme as configurações do repositório template.
  - Criar bloqueios para as branches:
    - `master`
    - `develop`
    - `release/*`
  - Habilitar as seguintes opções:
    - **Require a pull request before merging**
      - **Require approvals**:
        - Required number of approvals before merging: 1
      - **Require review from Code Owners**
    - **Require status checks to pass before merging**
      - Como já foi startado o workflow, adicionar o Check Dependency Review como obritatório.
      - Após o código ser adicionado pelo time de desenvolvimento, incluir o CodeQL o tfsec como obrigatório.
      - **OBSERVAÇÃO**
        - Na branch master, deixar marcado **Do not allow bypassing the above settings**

### 7. Deixar o sonar-project.properties em branco

### 8. Secrets - Enable Push Protection Bypass 
- Em GitHub, acesse a página principal do repositório.
- Abaixo do nome do repositório, clique em  Configurações. Caso não consiga ver a guia "Configurações", selecione o menu suspenso  , clique em Configurações
  - Na seção "Segurança" da barra lateral, clique em  Advanced Security.
  - Em "Secret Protection", verifique se a proteção de push está habilitada para o repositório.
  - Em "Push protection", à direita de "Who can bypass push protection for secret scanning", selecione o menu suspenso e clique em Funções ou equipes específicas.
  - Em "Bypass list", clique em Add role or team.
  - Na caixa de diálogo, selecionea a equipe admin-access-all-repositories  e clique em Adicionar selecionados.




