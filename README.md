

\# Smartphone Virtual Lighting Studio 📸💡



\*\*A mobile photography lighting application built with Flutter and Python.\*\*



\## 1. Overview



Smartphone Virtual Lighting Studio is a mobile application designed to make creative photography lighting more accessible and affordable. It combines smartphone hardware capabilities with digital image-processing techniques to help users achieve studio-inspired lighting effects without purchasing expensive photography equipment.



The application explores two complementary approaches to lighting:



\- \*\*Physical Lighting:\*\* Uses the smartphone's built-in flashlight to illuminate people and objects during photography.

\- \*\*Digital Lighting:\*\* Allows users to enhance photographs with adjustable virtual lighting effects, including spotlights, colors, intensity and softness.



By combining these approaches, users can capture photographs using available physical light and further customize their appearance through digital editing.



\## 2. The Problem



Professional photography lighting equipment, such as ring lights, softboxes, reflectors and RGB lights, can be expensive, inconvenient to carry and inaccessible to everyday smartphone photographers.



Although smartphones already have built-in flashlights and cameras, these features offer limited control over the lighting effects users want to achieve.



Smartphone Virtual Lighting Studio explores an alternative: making creative lighting tools accessible through software and hardware that users already own.



\## 3. Features



\### Physical Lighting

\- Control the smartphone flashlight.

\- Turn the torch on and off.

\- Support flashlight intensity adjustments where the device allows them.

\- Use physical illumination while positioning the phone to light a subject.



\### Digital Lighting

\- Add circular spotlight effects to photographs.

\- Adjust spotlight position and size.

\- Control lighting intensity.

\- Adjust edge softness for smoother lighting transitions.

\- Apply different lighting colors.



\### Color Customization



The lighting palette includes:



\- White

\- Warm

\- Orange

\- Red

\- Blue

\- Purple

\- Pink

\- Green



\### Photo Editing

\- Import photographs from the device.

\- Preview lighting modifications.

\- Customize lighting effects.

\- Undo and redo editing changes.

\- Reset adjustments.

\- Export edited photographs while preserving the original image.



\### Lighting Presets



The proposed preset collection includes:



\- Warm Portrait

\- Blue Studio

\- Product Spotlight



\## 4. Technology Stack



| Technology | Purpose |

|---|---|

| Flutter | Mobile application interface |

| Dart | Mobile application development |

| Python | Supporting processing and application logic |

| Android APIs | Access to smartphone hardware capabilities |

| Git \& GitHub | Version control and project management |



\## 5. System Architecture



The application follows a mobile-first approach, with Flutter providing the user interface and Python supporting the application's processing logic.



The main components are:



1\. \*\*Presentation Layer:\*\* Flutter screens, controls and user interactions.

2\. \*\*Hardware Layer:\*\* Smartphone camera and flashlight functionality.

3\. \*\*Processing Layer:\*\* Python-based supporting logic and image-processing operations.

4\. \*\*Image Management:\*\* Photograph importing, editing and exporting.



\### Application Workflow



```text

&#x20;         USER

&#x20;           |

&#x20;           v

&#x20;   FLUTTER APPLICATION

&#x20;           |

&#x20;     +-----+------+

&#x20;     |            |

&#x20;     v            v

&#x20;  CAMERA       FLASHLIGHT

&#x20;     |            |

&#x20;     +------+-----+

&#x20;            |

&#x20;            v

&#x20;     PHOTO CAPTURE

&#x20;            |

&#x20;            v

&#x20;    IMAGE PROCESSING

&#x20;       (PYTHON)

&#x20;            |

&#x20;            v

&#x20;    DIGITAL LIGHTING

&#x20;            |

&#x20;            v

&#x20;     PHOTO PREVIEW

&#x20;            |

&#x20;            v

&#x20;     EXPORT / SHARE

```



\## 6. Project Structure



```text

smartphone-virtual-lighting-studio/

│

├── frontend/

│   ├── lib/

│   │   ├── main.dart

│   │   │

│   │   ├── screens/

│   │   │   ├── home\_screen.dart

│   │   │   ├── camera\_screen.dart

│   │   │   ├── lighting\_screen.dart

│   │   │   └── editor\_screen.dart

│   │   │

│   │   ├── widgets/

│   │   │   ├── spotlight\_controls.dart

│   │   │   ├── color\_picker.dart

│   │   │   └── lighting\_slider.dart

│   │   │

│   │   ├── services/

│   │   │   ├── camera\_service.dart

│   │   │   ├── flashlight\_service.dart

│   │   │   └── image\_service.dart

│   │   │

│   │   ├── models/

│   │   │   └── lighting\_settings.dart

│   │   │

│   │   └── utils/

│   │

│   ├── assets/

│   ├── test/

│   └── pubspec.yaml

│

├── backend/

│   ├── main.py

│   │

│   ├── image\_processing/

│   │   ├── \_\_init\_\_.py

│   │   ├── spotlight.py

│   │   ├── color\_adjustment.py

│   │   └── image\_blending.py

│   │

│   ├── services/

│   │   └── lighting\_service.py

│   │

│   ├── utils/

│   │

│   └── requirements.txt

│

├── docs/

│   └── project\_overview.pdf

│

├── .gitignore

├── LICENSE

└── README.md

```



\*Note: This is a suggested structure. Replace the example filenames with your actual project files.\*



\## 7. Getting Started



\### Prerequisites



Before running the project, make sure you have:



\- Flutter SDK installed.

\- Dart SDK.

\- Python 3 installed.

\- Android Studio or another compatible development environment.

\- An Android smartphone or emulator.



\### Clone the Repository



```bash

git clone https://github.com/YOUR\_USERNAME/smartphone-virtual-lighting-studio.git



cd smartphone-virtual-lighting-studio

```



\### Set Up the Flutter Application



```bash

cd mobile



flutter pub get



flutter run

```



\### Set Up the Python Environment



Open another terminal:



```bash

cd backend



python -m venv venv

```



Activate the virtual environment.



\*\*Windows:\*\*



```bash

venv\\Scripts\\activate

```



\*\*Linux / macOS:\*\*



```bash

source venv/bin/activate

```



Install the required dependencies:



```bash

pip install -r requirements.txt

```



Run the Python application using its configured entry point:



```bash

uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

```



\*Note: These instructions assume the suggested folder structure and a Python entry point named `main.py`. Adjust the commands to match your implementation.\*



\## 8. How It Works



The intended user workflow consists of six main steps:



1\. \*\*Open:\*\* Launch the application and select Physical Lighting or Digital Lighting.

2\. \*\*Set Up:\*\* Configure the available lighting options.

3\. \*\*Illuminate:\*\* Activate the smartphone flashlight where supported.

4\. \*\*Capture:\*\* Take a photograph using the camera.

5\. \*\*Customize:\*\* Adjust the spotlight's color, position, size, intensity and softness.

6\. \*\*Export:\*\* Save or share the enhanced photograph.



\## 9. Technical Considerations



The application works within the limitations of smartphone hardware.



\- Flashlight brightness adjustment depends on device support.

\- A software application cannot physically transform a standard white LED into an RGB light.

\- Digital color effects modify the photograph rather than changing the physical light emitted by the phone.

\- The quality of physical illumination varies across smartphone models.

\- Digital lighting effects may not perfectly reproduce real-world reflections and shadows.



These limitations make device compatibility and realistic image processing important considerations.



\## 10. Future Improvements



Potential future development directions include:



\- AI-powered subject detection and background separation.

\- More realistic lighting and blending algorithms.

\- Additional customizable lighting presets.

\- Improved compatibility across Android devices.

\- Video lighting and real-time effects.

\- Cloud backup and synchronization.

\- Multi-phone synchronized lighting.

\- iOS support.



\## 11. Scalability and Performance



The proposed architecture prioritizes on-device camera operations and image processing to reduce unnecessary server costs and network dependencies.



Future cloud functionality could support analytics, crash reporting, remote configurations and optional synchronization.



Performance improvements should focus on:



\- Responsive editing controls.

\- Efficient image processing.

\- Reduced memory consumption.

\- Reliable photograph exports.

\- Testing across low-, mid- and high-range Android devices.



\## 12. Contributing



Contributions, suggestions and improvements are welcome.



To contribute:



1\. Fork the repository.

2\. Create a feature branch.

3\. Implement your changes.

4\. Test your implementation.

5\. Submit a pull request describing your contribution.



\## 13. License



This project is available under the MIT License. See the `LICENSE` file for details.



\---



\*\*Smartphone Virtual Lighting Studio\*\*



\*Making creative photography lighting more accessible, one smartphone at a time.\* 📸



