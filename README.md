# Recompactador


```bash
ruby recompactador.rb zip_ou_pasta nome_prefixo_arquivo_destino tamanho_arquivo_gerado_em_mb
```

**zip_ou_pasta**
(obrigatório):
Caminho completo para o arquivo ZIP a ser recompactado ou caminho da pasta
contendo os arquivos (não zip) a serem compactados.

**nome_prefixo_arquivo_destino**
(padrão: nome do arquivo sem sua extensão ou nome pasta):
Nome utilizado para gerar os novos arquivos compactados (não informe extensão)

**tamanho_arquivo_gerado_em_mb**
(padrão: 50mb):
Tamanho máximo que cada novo arquivo compactado deverá ter.

### Exemplo de Uso
```bash
ruby recompactador.rb xmls11.zip novos_xml 20
```
Resulta em novos_xml_1.zip, novos_xml_2.zip, ..., com no máximo 20mb cada

```bash
ruby recompactador.rb pastaxmls
```
Resulta em pastaxmls_1.zip, pastaxmls_2.zip, ..., com no máximo 50mb cada

```bash
ruby recompactador.rb pastaxmls xmls 100
```
Resulta em xmls_1.zip, xmls_2.zip, ..., com no máximo 100mb cada
