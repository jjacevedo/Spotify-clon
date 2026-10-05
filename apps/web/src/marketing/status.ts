export type FeatureStatus = 'works-today' | 'in-progress';

/**
 * Same order as copy.features.cards. Flip a card only when the feature works
 * for an invited user on the deployed app, not when the code is merged.
 */
export const featureStatus: readonly FeatureStatus[] = [
  'in-progress',
  'in-progress',
  'in-progress',
  'in-progress',
  'in-progress',
  'in-progress',
  'in-progress',
  'in-progress',
];

/** true once /login exists (milestone 1a): shows the header "Log in" link and the final "Log in" button. */
export const loginAvailable: boolean = false;
