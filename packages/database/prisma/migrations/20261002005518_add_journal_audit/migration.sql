-- CreateTable
CREATE TABLE "journaux_audit" (
    "id" UUID NOT NULL,
    "administrateur_id" UUID,
    "action" TEXT NOT NULL,
    "resource_type" TEXT NOT NULL,
    "resource_id" TEXT NOT NULL,
    "adresse_ip" TEXT,
    "details" JSONB,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "journaux_audit_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "journaux_audit_administrateur_id_idx" ON "journaux_audit"("administrateur_id");

-- CreateIndex
CREATE INDEX "journaux_audit_resource_type_resource_id_idx" ON "journaux_audit"("resource_type", "resource_id");

-- CreateIndex
CREATE INDEX "journaux_audit_date_creation_idx" ON "journaux_audit"("date_creation");

-- AddForeignKey
ALTER TABLE "journaux_audit" ADD CONSTRAINT "journaux_audit_administrateur_id_fkey" FOREIGN KEY ("administrateur_id") REFERENCES "utilisateurs"("id") ON DELETE SET NULL ON UPDATE CASCADE;
