from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4

import aiofiles
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from sqlalchemy import DateTime, Integer, String, create_engine, select
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column

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

app = FastAPI(title="Aesthetic Camera API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/photos")
async def upload_photo(file: UploadFile = File(...)) -> dict[str, object]:
    content_type = file.content_type or ""
    if not content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")

    extension = Path(file.filename or "photo.jpg").suffix.lower() or ".jpg"
    stored_name = f"{uuid4().hex}{extension}"
    destination = UPLOAD_DIR / stored_name

    async with aiofiles.open(destination, "wb") as output:
        while chunk := await file.read(1024 * 1024):
            await output.write(chunk)

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


def _photo_payload(photo: Photo) -> dict[str, object]:
    return {
        "id": photo.id,
        "filename": photo.filename,
        "original_name": photo.original_name,
        "created_at": photo.created_at.isoformat(),
        "url": f"/photos/{photo.id}/file",
    }
