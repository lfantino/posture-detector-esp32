# Gestió de la Pantalla de Calibració i Llindars (Thresholds)

Aquest pla detalla com transformarem la pantalla de calibració estàtica actual en un procés guiat (wizard) pas a pas, i com integrarem els valors obtinguts per a substituir les constants actuals de `posture_control.dart`.


## Decisions preses

1. **Marges (a, b, c, d):** Farem servir 5 cm per a/b i 250 per a c/d.
2. **Estructura de la Base de Dades:** No es toca la DB. Es deixa una nota (TODO) indicant que s'haurà d'actualitzar en el futur. 
3. **Constants a Variables:** A `posture_control.dart`, convertirem els `kMax...` en variables amb un mètode `loadThresholds()`.
4. **Pas 3 (Calibració Lateral):** Per agilitzar, fem que el Pas 3 sigui un sol pas visualment, però l'usuari haurà de prémer primer un botó "Gravar Costat Esquerre" i, quan el premi, apareixerà el botó "Gravar Costat Dret".
5. **Vídeos i Imatges:** Usarem caixes grises amb icones de "Play" com a placeholders pels futurs vídeos.

## Proposed Changes

### Pantalla de Calibració (UI i Lògica)
#### [MODIFY] `lib/screens/calibracion_page.dart`
- Convertir de `StatelessWidget` a `StatefulWidget`.
- Crear una màquina d'estats per als passos:
  - Pas 0: Introducció.
  - Pas 1.1: Ultrasons esquena (Recte).
  - Pas 1.2: Ultrasons esquena (Inclinat).
  - Pas 2: Frontal coixí inferior (Punta).
  - Pas 3: Lateral coixí inferior (Esquerra i Dreta).
  - Pas 4: Resum i Guardar.
- Llegir dades en temps real des de `PostureController.instance` quan l'usuari preme el botó de gravar en cada pas.
- Realitzar els càlculs especificats per establir els 6 thresholds i sumar-hi els marges (a=5, b=5, c=250, d=250).

### Base de Dades
#### [NO CHANGES] `lib/database/database_helper.dart`
- No modificarem l'schema de moment.
- *Nota a afegir al codi: TO-DO: Modificar la taula de calibracions per encabir els nous thresholds.*

### Control de Postura
#### [MODIFY] `lib/posture_control.dart`
- Eliminar les constants hardcoded (`const double kMax...`).
- Crear variables d'estat per a aquests llindars dins la classe amb els valors per defecte actuals.
- Afegir un mètode `loadThresholds()` per poder injectar la nova calibració a les variables en qualsevol moment.


