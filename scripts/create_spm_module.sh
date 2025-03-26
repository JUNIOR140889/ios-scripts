#!/bin/bash

# ---------------------------------------------------------------------------
# USO:
#   ./create_spm_module.sh NombreDelModulo
#
# DESCRIPCIÓN:
#   Crea un directorio con el nombre especificado, inicializa un paquete Swift
#   y configura la estructura básica para un módulo de SPM.
#
# REQUISITOS:
#   - Tener instalado Swift en tu entorno (Swift 5.3 o superior).
#   - Ejecución en un entorno tipo Unix (macOS, Linux, WSL, etc.).
#
# ---------------------------------------------------------------------------

# Verificar que se haya proporcionado un nombre de módulo
if [ -z "$1" ]; then
  echo "Error: Debes indicar el nombre del módulo."
  echo "Ejemplo: ./create_spm_module.sh MiNuevoModulo"
  exit 1
fi

MODULE_NAME=$1

# Crear carpeta del módulo
mkdir "$MODULE_NAME"
cd "$MODULE_NAME" || exit 1

# Inicializar el paquete Swift con tipo 'library'
swift package init --type library

# Mensaje de confirmación
echo "---------------------------------------------"
echo "Se ha creado el paquete Swift '$MODULE_NAME'."
echo "Estructura generada:"
tree .
echo "---------------------------------------------"

# Sugerencia para editar el Package.swift
echo "Ahora puedes editar el archivo Package.swift y ajustar la versión mínima de iOS, las dependencias, etc."
echo "Por ejemplo, para especificar iOS 14 y añadir recursos:"
echo ""
echo "----------------------------------------------------"
echo "Ejemplo de secciones en Package.swift:"
echo ""
echo "platforms: ["
echo "    .iOS(.v14)"
echo "],"
echo ""
echo "targets: ["
echo "    .target("
echo "        name: \"$MODULE_NAME\","
echo "        resources: ["
echo "            .process(\"Resources\")"
echo "        ]"
echo "    ),"
echo "    .testTarget("
echo "        name: \"${MODULE_NAME}Tests\","
echo "        dependencies: [\"$MODULE_NAME\"]"
echo "    )"
echo "]"
echo "----------------------------------------------------"
echo "¡Listo! Ya tienes tu nuevo módulo SPM."
