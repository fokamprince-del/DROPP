/*
  Warnings:

  - Made the column `telephone` on table `utilisateurs` required. This step will fail if there are existing NULL values in that column.

*/
-- AlterTable
ALTER TABLE "utilisateurs" ALTER COLUMN "telephone" SET NOT NULL;
