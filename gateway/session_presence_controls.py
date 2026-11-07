from __future__ import annotations

import asyncio
from functools import partial
from pathlib import Path

from pydantic import ValidationError

from gateway.reach_presence import AttentionState, ClientKind, Device, declare, report_attention
from hermes_state_runtime import RuntimeStoreError


def _authority_home(authority) -> Path:
    return Path(authority.db.db_path).resolve().parent


def _same_host(connection) -> bool:
    return bool(connection.native_owner or getattr(connection.transport, 'desktop_local', False))


def _require_actor(connection) -> None:
    if not connection.actor.capabilities:
        raise RuntimeStoreError('permission_denied')


async def hello(connection, ref, params):
    from tui_gateway.contracts.canonical_reach import ClientHelloParams
    _require_actor(connection)
    try:
        parsed = ClientHelloParams.model_validate(params)
    except ValidationError as exc:
        raise RuntimeStoreError('invalid_params') from exc
    label = ' '.join(parsed.label.split())
    if not label or not label.isprintable():
        raise RuntimeStoreError('invalid_params')
    device = Device(kind=ClientKind(parsed.kind), device_id=parsed.device_id, label=label,
                    app_version=parsed.app_version.strip())
    slot = declare(connection.transport, device, accepts_offers=parsed.accepts_offers,
                   same_host=_same_host(connection), attention=AttentionState(parsed.attention),
                   device_tools=parsed.device_tools and device.kind is ClientKind.IOS)
    if slot.device_tools:
        from gateway import device_connectors
        try:
            await asyncio.to_thread(device_connectors.register_device, _authority_home(connection.authority),
                                    device.device_id, device.label)
        except device_connectors.StoreUnreadable as exc:
            raise RuntimeStoreError('storage_unavailable', detail=str(exc)) from exc
    return {'recorded': True, 'same_host': slot.same_host}


async def attention(connection, ref, params):
    from tui_gateway.contracts.canonical_reach import ClientAttentionParams
    _require_actor(connection)
    try:
        parsed = ClientAttentionParams.model_validate(params)
    except ValidationError as exc:
        raise RuntimeStoreError('invalid_params') from exc
    return {'recorded': report_attention(connection.transport, AttentionState(parsed.state)) is not None}


def handlers(connection):
    return {'client.hello': partial(hello, connection), 'client.attention': partial(attention, connection)}
