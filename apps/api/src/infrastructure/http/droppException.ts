import { ERREUR_CODES } from "@dropp/contrats";
import { HttpException } from "@nestjs/common";

export type DroppExceptionParams = Record<string, string | number | boolean | string[]>;

export class DroppException extends HttpException {
    constructor(message: string, status: number, code: ERREUR_CODES, params?: DroppExceptionParams) {
        super({
            statusCode: status,
            message: message,
            code: code,
            ...(params ? { params } : {}),
        }, status);
    }

    static BadRequest(message: string, code: ERREUR_CODES, params?: DroppExceptionParams) {
        return new DroppException(message, 400, code, params);
    }

    static Unauthorized(message: string, code: ERREUR_CODES, params?: DroppExceptionParams) {
        return new DroppException(message, 401, code, params);
    }

    static Forbidden(message: string, code: ERREUR_CODES, params?: DroppExceptionParams) {
        return new DroppException(message, 403, code, params);
    }

    static NotFound(message: string, code: ERREUR_CODES, params?: DroppExceptionParams) {
        return new DroppException(message, 404, code, params);
    }

    static Conflict(message: string, code: ERREUR_CODES, params?: DroppExceptionParams) {
        return new DroppException(message, 409, code, params);
    }

    static Gone(message: string, code: ERREUR_CODES, params?: DroppExceptionParams) {
        return new DroppException(message, 410, code, params);
    }

    static InternalServerError(message: string, code: ERREUR_CODES, params?: DroppExceptionParams) {
        return new DroppException(message, 500, code, params);
    }

    static ServiceUnavailable(message: string, code: ERREUR_CODES, params?: DroppExceptionParams) {
        return new DroppException(message, 503, code, params);
    }

    static UnprocessableEntity(message: string, code: ERREUR_CODES, params?: DroppExceptionParams) {
        return new DroppException(message, 422, code, params);
    }
}