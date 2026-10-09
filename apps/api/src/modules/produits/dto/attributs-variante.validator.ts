import { ValidateBy, type ValidationOptions } from 'class-validator';

const MAX_ATTRIBUTS = 10;
const MAX_LONGUEUR = 100;

/**
 * Attributs d'une variante : objet plat { "taille": "XL", "couleur": "rouge" },
 * au plus 10 entrées, clés et valeurs texte non vides de 100 caractères max.
 */
export function EstAttributsVariante(options?: ValidationOptions) {
  return ValidateBy(
    {
      name: 'estAttributsVariante',
      validator: {
        validate: (valeur: unknown) => {
          if (typeof valeur !== 'object' || valeur === null || Array.isArray(valeur)) {
            return false;
          }
          const entrees = Object.entries(valeur);
          return (
            entrees.length <= MAX_ATTRIBUTS &&
            entrees.every(
              ([cle, v]) =>
                cle.trim().length > 0 &&
                cle.length <= MAX_LONGUEUR &&
                typeof v === 'string' &&
                v.trim().length > 0 &&
                v.length <= MAX_LONGUEUR,
            )
          );
        },
        defaultMessage: () =>
          `Attributs invalides : ${MAX_ATTRIBUTS} au plus, clés et valeurs texte de ${MAX_LONGUEUR} caractères max.`,
      },
    },
    options,
  );
}
