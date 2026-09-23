-- CreateEnum
CREATE TYPE "RoleUtilisateur" AS ENUM ('CLIENT', 'VENDEUR', 'ADMIN');

-- CreateEnum
CREATE TYPE "FournisseurAuthentification" AS ENUM ('GOOGLE', 'FACEBOOK', 'APPLE', 'EMAIL');

-- DropForeignKey
ALTER TABLE "utilisateur_roles" DROP CONSTRAINT "utilisateur_roles_role_id_fkey";

-- AddForeignKey
ALTER TABLE "utilisateur_roles" ADD CONSTRAINT "utilisateur_roles_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "roles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;


