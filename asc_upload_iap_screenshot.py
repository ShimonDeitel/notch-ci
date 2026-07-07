#!/usr/bin/env python3
"""Upload the App Store review screenshot for an in-app purchase via the ASC API.
Requires env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH, IAP_ID, SCREENSHOT_PATH
"""
import hashlib
import json
import os
import sys
import time
import urllib.request
import urllib.error

import jwt

ASC_KEY_ID = os.environ["ASC_KEY_ID"]
ASC_ISSUER_ID = os.environ["ASC_ISSUER_ID"]
ASC_KEY_PATH = os.environ["ASC_KEY_PATH"]
IAP_ID = os.environ["IAP_ID"]
SCREENSHOT_PATH = os.environ["SCREENSHOT_PATH"]

BASE = "https://api.appstoreconnect.apple.com/v1"


def make_jwt():
    with open(ASC_KEY_PATH) as f:
        private_key = f.read()
    now = int(time.time())
    payload = {"iss": ASC_ISSUER_ID, "iat": now, "exp": now + 19 * 60, "aud": "appstoreconnect-v1"}
    headers = {"kid": ASC_KEY_ID, "typ": "JWT"}
    return jwt.encode(payload, private_key, algorithm="ES256", headers=headers)


def req(method, path, token, body=None):
    url = path if path.startswith("http") else BASE + path
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(url, data=data, method=method)
    r.add_header("Authorization", f"Bearer {token}")
    r.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(r) as resp:
            raw = resp.read()
            return resp.status, (json.loads(raw) if raw else {})
    except urllib.error.HTTPError as e:
        raw = e.read()
        print(f"HTTP {e.code} on {method} {url}: {raw.decode()[:2000]}", file=sys.stderr)
        raise


def main():
    token = make_jwt()

    status, iap = req("GET", f"/inAppPurchases/{IAP_ID}", token)
    state = iap.get("data", {}).get("attributes", {}).get("state")

    # An IAP review screenshot may already exist from a prior successful run even
    # while the IAP's overall `state` hasn't flipped away from MISSING_METADATA
    # (e.g. other required metadata is still pending). Check the actual
    # relationship for an existing screenshot and skip if one is already there —
    # otherwise the POST below 409s with ENTITY_ERROR.MEDIA_ASSET_CREATION_NOT_ALLOWED.
    status, existing = req(
        "GET", f"/inAppPurchases/{IAP_ID}/appStoreReviewScreenshot", token
    )
    if existing.get("data"):
        existing_id = existing["data"]["id"]
        print(f"IAP already has review screenshot {existing_id} — skipping upload.")
        print("IAP_SCREENSHOT_UPLOAD_COMPLETE")
        print(f"IAP_SCREENSHOT_ID={existing_id}")
        return

    if state != "MISSING_METADATA":
        print(f"IAP state is {state}, not MISSING_METADATA — screenshot already uploaded, skipping.")
        return

    with open(SCREENSHOT_PATH, "rb") as f:
        content = f.read()
    file_size = len(content)
    file_name = os.path.basename(SCREENSHOT_PATH)

    body = {
        "data": {
            "type": "inAppPurchaseAppStoreReviewScreenshots",
            "attributes": {"fileName": file_name, "fileSize": file_size},
            "relationships": {"inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": IAP_ID}}},
        }
    }
    try:
        status, reservation = req("POST", "/inAppPurchaseAppStoreReviewScreenshots", token, body)
    except urllib.error.HTTPError as e:
        if e.code == 409:
            print("Screenshot already exists (409) — treating as already uploaded.")
            print("IAP_SCREENSHOT_UPLOAD_COMPLETE")
            return
        raise
    print("reservation", status)
    ss_id = reservation["data"]["id"]
    upload_ops = reservation["data"]["attributes"]["uploadOperations"]

    for op in upload_ops:
        offset = op["offset"]
        length = op["length"]
        chunk = content[offset:offset + length]
        r = urllib.request.Request(op["url"], data=chunk, method=op["method"])
        for h in op["requestHeaders"]:
            r.add_header(h["name"], h["value"])
        with urllib.request.urlopen(r) as resp:
            print(f"PUT chunk offset={offset} len={length} status={resp.status}")

    checksum = hashlib.md5(content).hexdigest()
    patch_body = {
        "data": {
            "type": "inAppPurchaseAppStoreReviewScreenshots",
            "id": ss_id,
            "attributes": {"uploaded": True, "sourceFileChecksum": checksum},
        }
    }
    status, result = req("PATCH", f"/inAppPurchaseAppStoreReviewScreenshots/{ss_id}", token, patch_body)
    print("patch uploaded", status)

    for _ in range(30):
        status, check = req("GET", f"/inAppPurchaseAppStoreReviewScreenshots/{ss_id}", token)
        state = check["data"]["attributes"]["assetDeliveryState"]["state"]
        print(f"assetDeliveryState={state}")
        if state == "COMPLETE":
            print("IAP_SCREENSHOT_UPLOAD_COMPLETE")
            print(f"IAP_SCREENSHOT_ID={ss_id}")
            return
        if state == "FAILED":
            print("IAP_SCREENSHOT_UPLOAD_FAILED", check["data"]["attributes"]["assetDeliveryState"])
            sys.exit(1)
        time.sleep(3)
    print("Timed out waiting for COMPLETE state")
    sys.exit(1)


if __name__ == "__main__":
    main()
