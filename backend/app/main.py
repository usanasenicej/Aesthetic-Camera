from datetime import datetime, timezone
from io import BytesIO
from pathlib import Path
from uuid import uuid4

import aiofiles
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, Response
from PIL import Image
from sqlalchemy import DateTime, Integer, String, create_engine, select
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column

from app.services.lighting_service import LightingRequest, PRESETS, process_lighting

MAX_IMAGE_BYTES = 15 * 1024 * 1024

BASE_DIR = Path(__file__).resolve().parent.parent
UPLOAD_DIR = BASE_DIR / "uploads"
UPLOAD_DIR.mkdir(exist_ok=True)
DB_PATH = BASE_DIR / "photos.db"

engine = create_engine(
    f"sqlite:///{DB_PATH}",
    connect_args={"check_same_thread": False},
)


class Base(DeclarativeBase):
    pass


class Photo(Base):
    __tablename__ = "photos"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    filename: Mapped[str] = mapped_column(String, unique=True)
    original_name: Mapped[str] = mapped_column(String)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=lambda: datetime.now(timezone.utc)
    )


Base.metadata.create_all(engine)

app = FastAPI(title="Virtual Lighting Studio API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "processing": "optional"}


@app.get("/lighting/presets")
def lighting_presets() -> dict[str, object]:
    return PRESETS


@app.post("/lighting/process")
async def lighting_process(
    file: UploadFile = File(...),
    center_x: float = Form(0.5),
    center_y: float = Form(0.5),
    radius: float = Form(0.45),
    intensity: float = Form(0.55),
    softness: float = Form(0.6),
    color_r: int = Form(255),
    color_g: int = Form(255),
    color_b: int = Form(255),
) -> Response:
    image_bytes = await _read_image_bytes(file)

    try:
        processed = process_lighting(
            image_bytes,
            LightingRequest(
                center_x=center_x,
                center_y=center_y,
                radius=radius,
                intensity=intensity,
                softness=softness,
                color=(color_r, color_g, color_b),
            ),
        )
    except Exception as error:  # noqa: BLE001 - return a clean API error
        raise HTTPException(status_code=400, detail=f"Could not process image: {error}") from error

    return Response(content=processed, media_type="image/jpeg")


@app.post("/photos")
async def upload_photo(file: UploadFile = File(...)) -> dict[str, object]:
    image_bytes = await _read_image_bytes(file)

    extension = Path(file.filename or "photo.jpg").suffix.lower() or ".jpg"
    stored_name = f"{uuid4().hex}{extension}"
    destination = UPLOAD_DIR / stored_name

    async with aiofiles.open(destination, "wb") as output:
        await output.write(image_bytes)

    with Session(engine) as session:
        photo = Photo(filename=stored_name, original_name=file.filename or stored_name)
        session.add(photo)
        session.commit()
        session.refresh(photo)
        return _photo_payload(photo)


@app.get("/photos")
def list_photos() -> list[dict[str, object]]:
    with Session(engine) as session:
        photos = session.scalars(select(Photo).order_by(Photo.id.desc())).all()
        return [_photo_payload(photo) for photo in photos]


@app.get("/photos/{photo_id}/file")
def get_photo_file(photo_id: int) -> FileResponse:
    with Session(engine) as session:
        photo = session.get(Photo, photo_id)
        if photo is None:
            raise HTTPException(status_code=404, detail="Photo not found")

        path = UPLOAD_DIR / photo.filename
        if not path.exists():
            raise HTTPException(status_code=404, detail="Photo file missing")

        return FileResponse(path, media_type="image/jpeg", filename=photo.original_name)


async def _read_image_bytes(file: UploadFile) -> bytes:
    content_type = file.content_type or ""
    if content_type and not content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")

    image_bytes = await file.read(MAX_IMAGE_BYTES + 1)
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Empty image")
    if len(image_bytes) > MAX_IMAGE_BYTES:
        raise HTTPException(status_code=413, detail="Image is larger than 15 MB")

    try:
        with Image.open(BytesIO(image_bytes)) as image:
            image.verify()
    except Exception as error:  # noqa: BLE001
        raise HTTPException(status_code=400, detail="File must be a valid image") from error

    return image_bytes


def _photo_payload(photo: Photo) -> dict[str, object]:
    return {
        "id": photo.id,
        "filename": photo.filename,
        "original_name": photo.original_name,
        "created_at": photo.created_at.isoformat(),
        "url": f"/photos/{photo.id}/file",
    }
