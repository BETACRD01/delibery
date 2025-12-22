#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import os
import sys
from urllib.parse import urljoin

import requests


def _get_token(base_url):
    token = os.getenv("API_TOKEN")
    if token:
        return token

    identificador = os.getenv("API_IDENTIFICADOR")
    password = os.getenv("API_PASSWORD")
    if not identificador or not password:
        raise SystemExit(
            "Falta API_TOKEN o API_IDENTIFICADOR/API_PASSWORD para autenticar."
        )

    login_url = urljoin(base_url, "auth/login/")
    response = requests.post(
        login_url,
        json={"identificador": identificador, "password": password},
        timeout=15,
    )
    response.raise_for_status()
    data = response.json()
    return data["tokens"]["access"]


def _get_json(base_url, path, token):
    url = urljoin(base_url, path.lstrip("/"))
    response = requests.get(
        url,
        headers={"Authorization": f"Bearer {token}"},
        timeout=15,
    )
    print(f"\n{response.status_code} {url}")
    try:
        payload = response.json()
        print(json.dumps(payload, indent=2, ensure_ascii=False)[:4000])
    except ValueError:
        print(response.text[:4000])
    response.raise_for_status()


def main():
    base_url = os.getenv("API_BASE_URL", "http://localhost:8000/api/")

    if len(sys.argv) < 3 or len(sys.argv[1:]) % 2 != 0:
        raise SystemExit(
            "Uso: python backend/scripts/test_calificaciones_api.py "
            "<tipo> <id> [<tipo> <id> ...]\n"
            "Tipos soportados: producto, cliente, repartidor, proveedor"
        )

    token = _get_token(base_url)
    args = sys.argv[1:]

    for i in range(0, len(args), 2):
        entity_type = args[i]
        entity_id = args[i + 1]

        _get_json(
            base_url,
            f"calificaciones/{entity_type}/{entity_id}/",
            token,
        )
        _get_json(
            base_url,
            f"calificaciones/{entity_type}/{entity_id}/resumen/",
            token,
        )


if __name__ == "__main__":
    main()
