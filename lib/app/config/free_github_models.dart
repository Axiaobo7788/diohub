const freeGitHubModelIds = <String>{
  // --- OpenAI ---
  'openai/gpt-4o-mini',
  'openai/gpt-4.1-mini',
  'openai/gpt-4.1-nano',

  // --- Meta ---
  'meta/llama-4-scout',
  'meta/llama-4-maverick',

  // --- Mistral ---
  'mistral/mistral-small',

  // --- Microsoft ---
  'microsoft/phi-4',
  'microsoft/phi-4-mini',
};

/// Returns true if the given GitHub Models model ID is available to free users.
bool isFreeTierModel(String modelId) => freeGitHubModelIds.contains(modelId);
