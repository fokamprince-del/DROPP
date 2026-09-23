-- CreateTable
CREATE TABLE "reservations_stock" (
    "id" UUID NOT NULL,
    "variante_produit_id" UUID NOT NULL,
    "quantite" INTEGER NOT NULL,
    "expire_a" TIMESTAMPTZ(3) NOT NULL,
    "passage_commande_id" UUID,
    "date_creation" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "reservations_stock_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "reservations_stock_variante_produit_id_idx" ON "reservations_stock"("variante_produit_id");

-- CreateIndex
CREATE INDEX "reservations_stock_expire_a_idx" ON "reservations_stock"("expire_a");

-- AddForeignKey
ALTER TABLE "reservations_stock" ADD CONSTRAINT "reservations_stock_variante_produit_id_fkey" FOREIGN KEY ("variante_produit_id") REFERENCES "variantes_produits"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reservations_stock" ADD CONSTRAINT "reservations_stock_passage_commande_id_fkey" FOREIGN KEY ("passage_commande_id") REFERENCES "passages_commandes"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- addConstraint pour empecher les stocks negatifs
ALTER TABLE variantes_produits
  ADD CONSTRAINT chk_stock_non_negatif
  CHECK (stock_disponible >= 0); 
