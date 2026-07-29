# Skia-Slideshow
A high-performance, hardware-accelerated slideshow component for Delphi FMX, utilizing the power of Skia4Delphi. 
    
Skia-Slideshow v0.1 alpha   
   
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/LaMitaOne/Skia-Slideshow)    

Sample video: https://www.youtube.com/watch?v=P4ZQVMQxk3M         
    
<img width="360" height="202" alt="axpb44" src="https://github.com/user-attachments/assets/2f8b4834-1dd3-4e92-b1b5-e237e538c8ac" />
       
Inspired by the classic VCL TPicShow component, this project aims to bring smooth, modern, and cross-platform slideshow transitions to FMX using Skia's powerful 2D graphics engine.

    Status: Alpha (v0.1)This is an early preview release. While the core functionality works and the effects look great, the engine and rendering pipeline are still subject to optimization. Expect some performance hiccups during window resizing or on very large images.

✨ Features

    Hardware Acceleration: Rendered entirely via Skia for smooth, GPU-accelerated transitions.     
    Modular Effect Architecture: Effects are decoupled from the core engine using Interfaces (ISlideTransitionEffect), making it easy to add your own custom transitions.     
    Text Rendering: Native Skia text rendering for Titles, Captions, and debug information.
    Flexible Image Loading: Load images directly from files (JPG, PNG, etc.) or pass ISkImage objects directly.     

🎬 Included Transitions (9 Effects)

    Crossfade: Simple alpha blend.
    Slide Left: Image pushes in from the right.
    Zoom: Outgoing zooms in, incoming zooms out.
    Wipe Diagonal: Diagonal clipping mask reveal.
    Zoom Blur: Outgoing image zooms and blurs out.
    Reveal Center: Rectangle expanding from the center.
    Barn Doors: Two doors opening from the middle.
    Iris Circle: Circular reveal from the center.
    Clock Wipe: Radar-style 360-degree sweep.

🚀 Getting Started
Prerequisites

    Delphi 10.4 Sydney or newer.
    Skia4Delphi must be installed and configured in your IDE.

Quick Start Example:    
   zipped sample and project included    
     
⚠️ Known Issues & Roadmap

As this is an Alpha release, there are a few things to keep in mind:

     Resizing Performance: Resizing the window rapidly can cause slight stuttering as Skia recalculates the image drawing rectangles. A texture caching system is planned for the next update.
     More Effects: More complex 3D and masking effects are in development.

🤝 Contributing

This is a work in progress. If you have ideas for new transition effects or want to help optimize the rendering pipeline, feel free to fork the repo and submit a pull request!
📜 License

MIT License. Feel free to use this in your commercial and personal projects.   

     
   
If you want to tip me a coffee.. :)   
    
<p align="center">
  <a href="https://www.paypal.com/donate/?hosted_button_id=RX5KTTMXW497Q">
    <img src="https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif" alt="Donate with PayPal"/>
  </a>
</p>
        
