validate:
	@RPC_URL=$(RPC_URL) bash scripts/validate_claims.sh

new-claim:
	@./scripts/new_claim_and_push.sh $(FILE)
