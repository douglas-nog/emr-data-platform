## O que muda

<!-- Descrição objetiva. Se altera arquitetura, referencie o ADR. -->

## Tipo

- [ ] Infraestrutura (Terraform)
- [ ] Ingestão (PySpark)
- [ ] Transformação (dbt)
- [ ] Orquestração (Airflow)
- [ ] Documentação / ADR

## Checklist

- [ ] `make lint` passa
- [ ] `terraform plan` revisado e sem mudança destrutiva não intencional
- [ ] Contrato dbt atualizado, se o schema de SOT ou SPEC mudou
- [ ] Modelo `public` alterado tem bump de versão, se a mudança é incompatível
- [ ] ADR criado ou atualizado, se houve decisão de arquitetura
- [ ] Sem credencial, ARN de conta real ou segredo no diff
