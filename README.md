# iOS SPM Module Generator

Este repositorio contiene un script en Bash para generar nuevos módulos basados en Swift Package Manager (SPM). Con este script, podrás crear de forma rápida la estructura básica de un paquete Swift, facilitando la estandarización y generación de nuevos módulos en tu monorepo.

## Contenido

- **scripts/create_spm_module.sh:** Script que genera un nuevo módulo SPM.
- **README.md:** Este archivo, con instrucciones de uso.

## Requisitos

- **Swift:** Se requiere Swift 5.3 o superior.
- **Bash:** El script está escrito en Bash (compatible con macOS, Linux y otros entornos Unix-like).
- **Conexión a Internet:** Solo es necesaria si deseas ejecutar el script directamente desde GitHub.

## Uso

### Ejecución directa desde GitHub

Puedes ejecutar el script sin necesidad de clonar el repositorio usando el siguiente comando:

```bash
curl -sL https://raw.githubusercontent.com/JUNIOR140889/ios-scripts/main/scripts/create_spm_module.sh | bash -s NombreDelModulo
