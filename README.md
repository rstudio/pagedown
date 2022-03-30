# PrysDown

> Este paquete esta basado en [pagedown](https://github.com/rstudio/pagedown).

## Uso de los templates personalizados

### Propuestas, cartas, contratos, etc

Para escribir una propuesta, carta, contrato, etc con el formato de ProyAIS se
debe utilizar la fución `prysdown::html_propuesta` en el parámetro `output` del
documento Rmarkdown.

Para diligenciar la información de quien envía se debe seguir el siguiente esquema:

```markdown
::: from
Información de quien envía
:::
```

Para la información de quien recibirá se utiliza:

```markdown
::: to
Información de quien recibirá el documento
:::
```

Para agregar un campo de firma se utiliza:
```markdown
::: sign
Información de quien firma
:::
```

Para agregar el logo se debe utilizar:
```markdown
![El logo de ProyAIS](https://raw.githubusercontent.com/proyais/marca/master/imagenes/proyais/titulo_proyais_color.svg){.logo}
```
