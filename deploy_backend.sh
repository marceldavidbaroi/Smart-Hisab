#!/bin/bash

# Exit on error
set -e

# Load environment variables from web/.env if it exists
if [ -f "web/.env" ]; then
  # Filter comments and export vars
  export $(grep -v '^#' web/.env | xargs)
fi

echo "=========================================="
echo "🚀 Deploying Supabase Backend..."
echo "=========================================="

# Set default project ref if not set
SUPABASE_PROJECT_REF="${SUPABASE_PROJECT_REF:-ragbgcqewutilfsiuief}"

# Link to the remote Supabase project
echo "🔗 Linking to Supabase project ref: $SUPABASE_PROJECT_REF..."
npx supabase link --project-ref "$SUPABASE_PROJECT_REF"


# Push database migrations to remote project
echo "📤 Pushing database migrations..."
npx supabase db push --linked

# Generate updated typescript types for the Quasar frontend
echo "📝 Generating TypeScript types..."
mkdir -p web/src/types
npx supabase gen types typescript --linked > web/src/types/supabase.ts

echo "=========================================="
echo "✅ Backend deployed and types updated!"
echo "=========================================="
