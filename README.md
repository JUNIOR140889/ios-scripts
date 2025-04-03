# Creación de Módulos SPM con create_spm_module.sh

Este script automatiza la creación de un módulo Swift Package Manager (SPM) junto con un Example App que integra el módulo como dependencia. El Example App se genera usando XcodeGen.


## Contenido

- **scripts/create_spm_module.sh:** Script que genera un nuevo módulo SPM.
- **README.md:** Este archivo, con instrucciones de uso.

## Requisitos

- Swift 5.3 o superior.
- XcodeGen (el script lo instalará vía Homebrew si no se encuentra).
- (Opcional) La utilidad tree para visualizar la estructura del proyecto.

## Uso

### Ejecución directa desde GitHub

Puedes ejecutar el script sin necesidad de clonar el repositorio usando el siguiente comando:

```bash
curl -sL https://raw.githubusercontent.com/JUNIOR140889/ios-scripts/main/scripts/create_spm_module.sh | bash -s NombreDelModulo
