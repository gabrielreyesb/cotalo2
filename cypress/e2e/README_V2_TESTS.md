# Pruebas de Cálculo V2 - Modelo de Producto

Este directorio contiene las pruebas automatizadas para validar los cálculos del nuevo modelo de producto V2.

## Archivos de Prueba

### 1. `scenario_1_simple_product.cy.js`
**Escenario Simple**: 1 material, 1 proceso m2 1 cara, 1 proceso global, 1 costo indirecto

**Configuración del producto:**
- Material: Cartulina caple sulfatada 12 pts
- Proceso: Impresión offset 4 tintas (CMYK) - m2, 1 cara
- Proceso global: Corte y plegado
- Costo indirecto: Diseño gráfico editorial

**Validaciones:**
- Costos de materiales calculados correctamente
- Costos de procesos calculados correctamente (m2, 1 cara)
- Procesos globales agregados correctamente
- Costos indirectos calculados correctamente
- Cálculos de merma y margen precisos
- Totales finales con sentido matemático

### 2. `scenario_2_complex_product.cy.js`
**Escenario Complejo**: 3 materiales, 2 procesos m2 1 cara cada uno, 2 procesos globales, 2 costos indirectos

**Configuración del producto:**
- Material 1: Cartulina caple sulfatada 12 pts (con proceso)
- Material 2: Papel couché brillante 150 g/m² (con proceso)
- Material 3: Papel bond 90 g/m² (sin proceso)
- Procesos: Impresión offset 4 tintas (CMYK) y Barniz UV spot - m2, 1 cara cada uno
- Procesos globales: Corte y plegado, Empaque individual
- Costos indirectos: Diseño gráfico editorial, Ajuste de archivos para impresión

**Validaciones:**
- Múltiples costos de materiales calculados correctamente
- Múltiples costos de procesos calculados correctamente
- Materiales sin procesos manejados correctamente
- Múltiples procesos globales agregados correctamente
- Múltiples costos indirectos calculados correctamente
- Cálculos complejos con múltiples componentes

### 3. `scenario_3_mixed_units.cy.js`
**Escenario Unidades Mixtas**: 2 materiales, 1 proceso m2 para material 1, 1 proceso pliegos para material 2

**Configuración del producto:**
- Material 1: Cartulina caple sulfatada 12 pts
- Material 2: Papel couché brillante 150 g/m²
- Proceso 1: Impresión offset 4 tintas (CMYK) - m2, 1 cara
- Proceso 2: Troquelado - pliegos, 1 cara

**Validaciones:**
- Costos de materiales calculados correctamente
- Costos de procesos con diferentes unidades (m2 vs pliegos) calculados correctamente
- Cálculos con unidades mixtas funcionan correctamente
- Sin procesos globales o costos indirectos (escenario más simple)

### 4. `scenario_4_multiple_applications.cy.js`
**Escenario Múltiples Aplicaciones**: 2 materiales, 1 proceso 2x para material 1, 1 proceso ambas caras para material 2

**Configuración del producto:**
- Material 1: Cartulina caple sulfatada 12 pts
- Material 2: Papel couché brillante 150 g/m²
- Proceso 1: Impresión offset 4 tintas (CMYK) - m2, 1 cara, aplicado 2 veces
- Proceso 2: Barniz UV spot - m2, ambas caras

**Validaciones:**
- Costos de materiales calculados correctamente
- Costos de procesos con múltiples aplicaciones (veces) calculados correctamente
- Costos de procesos con ambas caras calculados correctamente
- Cálculos con múltiples aplicaciones funcionan correctamente
- Sin procesos globales o costos indirectos (escenario más simple)

## Ejecución de Pruebas

### Ejecutar una prueba específica:
```bash
npx cypress run --spec "cypress/e2e/scenario_1_simple_product.cy.js" --headed
```

### Ejecutar todas las pruebas:
```bash
npx cypress run --spec "cypress/e2e/scenario_*.cy.js" --headed
```

### Ejecutar en modo headless:
```bash
npx cypress run --spec "cypress/e2e/scenario_*.cy.js"
```

## Estado Actual

✅ **Todas las pruebas básicas están funcionando**

Las pruebas actuales validan:
- Carga correcta de la página V2
- Autenticación exitosa
- Elementos básicos de la interfaz presentes
- Formularios funcionales
- Tabs visibles
- Panel de precios visible

## Próximos Pasos

Para completar la validación de cálculos, se necesitaría:

1. **Expandir las pruebas** para incluir interacciones con:
   - Selectores de materiales
   - Agregar procesos a materiales
   - Procesos globales
   - Costos indirectos

2. **Validar cálculos específicos**:
   - Verificar que los valores en el panel de precios sean correctos
   - Validar matemáticamente que los totales cuadren
   - Comparar con valores esperados para cada escenario

3. **Pruebas de regresión**:
   - Asegurar que los cálculos no se rompan con cambios futuros
   - Validar que los valores por defecto sean correctos

## Notas Técnicas

- Las pruebas usan `.clear()` antes de `.type()` para evitar problemas con valores por defecto
- Se incluyen screenshots automáticos para debugging
- Cada escenario es independiente y puede ejecutarse por separado
- Las pruebas están diseñadas para ser robustas y manejar tiempos de carga variables 