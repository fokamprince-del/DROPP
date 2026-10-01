/*
  Warnings:

  - You are about to drop the `codes_verification` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "codes_verification" DROP CONSTRAINT "codes_verification_utilisateur_id_fkey";

-- DropTable
DROP TABLE "codes_verification";
