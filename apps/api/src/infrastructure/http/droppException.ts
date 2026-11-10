import { ERREUR_CODES } from "@dropp/contrats";
import { HttpException, HttpStatus } from "@nestjs/common";

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
        return new DroppException(message, HttpStatus.BAD_REQUEST, code, params);
    }

    static Unauthorized(message: string, code: ERREUR_CODES, params?: DroppExceptionParams) {
        return new DroppException(message, HttpStatus.UNAUTHORIZED, code, params);
    }

    static Forbidden(message: string, code: ERREUR_CODES, params?: DroppExceptionParams) {
        return new DroppException(message, HttpStatus.FORBIDDEN, code, params);
    }

    static NotFound(message: string, code: ERREUR_CODES, params?: DroppExceptionParams) {
        return new DroppException(message, HttpStatus.NOT_FOUND, code, params);
    }

    static Conflict(message: string, code: ERREUR_CODES, params?: DroppExceptionParams) {
        return new DroppException(message, HttpStatus.CONFLICT, code, params);
    }

    static Gone(message: string, code: ERREUR_CODES, params?: DroppExceptionParams) {
        return new DroppException(message, HttpStatus.GONE, code, params);
    }

    static InternalServerError(message: string, code: ERREUR_CODES, params?: DroppExceptionParams) {
        return new DroppException(message, HttpStatus.INTERNAL_SERVER_ERROR, code, params);
    }

    static ServiceUnavailable(message: string, code: ERREUR_CODES, params?: DroppExceptionParams) {
        return new DroppException(message, HttpStatus.SERVICE_UNAVAILABLE, code, params);
    }

    static UnprocessableEntity(message: string, code: ERREUR_CODES, params?: DroppExceptionParams) {
        return new DroppException(message, HttpStatus.UNPROCESSABLE_ENTITY, code, params);
    }
}