# ui.R

# Custom CSS for color scheme
customCSS <- HTML("
  .skin-blue .main-header .logo {
    background-color: #2C3E50;
  }
  .skin-blue .main-header .logo:hover {
    background-color: #2C3E50;
  }
  .skin-blue .main-header .navbar {
    background-color: #2C3E50;
  }
  .skin-blue .main-sidebar {
    background-color: #2C3E50;
  }
  .skin-blue .main-sidebar .sidebar .sidebar-menu .active a {
    background-color: #455668;
  }
  .song-list {
    margin-top: 20px;
    min-height: 100px;
    border: 1px solid #ddd;
    border-radius: 4px;
    padding: 10px;
  }
  .song-item {
    background: #f8f9fa;
    padding: 8px 12px;
    margin: 5px 0;
    border-radius: 4px;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  .remove-song {
    color: #dc3545;
    cursor: pointer;
  }
  .selectize-dropdown-content {
    max-height: 200px;
    overflow-y: auto;
  }
  /* Add menu icon styling */
  .menu-icon {
    width: 24px;
    height: 24px;
    vertical-align: left;
    margin-right: 8px;
  }

  /* Adjust the menu tab to align items properly */
  .menu-tab {
    display: flex;
    align-items: left;
  }

  /* Ensure the tab links use flex alignment */
  .navbar-nav > li > a {
    display: flex;
    align-items: left;
    justify-content: left;
  }

  /* Center the title and subtitle on the Analyse MDNA page */
  .mdna-page .main-title,
  .mdna-page .subtitle {
    text-align: center;
  }

  /* MDNA Container */
  .mdna-container {
    position: relative;
    width: 654px;
    height: 440px;
    margin: 0 auto;
    border-radius: 10px;
    background: #FFF;
    box-shadow: 0px 4px 12px 0px rgba(13, 10, 44, 0.06);
    overflow: hidden;
  }

  .mdna-visualization-container-custom {
    background: #F0F;
  }

  /* Center Icon and Label */
  .center-icon {
    position: absolute;
    left: 50%;
    top: 50%;
    transform: translate(-50%, -50%);
    text-align: center;
  }

  .center-icon .mdna-label {
    display: block;
    margin-bottom: 10px;
    font-size: 16px;
    color: #333;
  }

  .center-icon .your-mdna-icon {
    width: 57px;
    height: 57px;
  }

  /* Suggested Song Icons */
  .suggested-song {
    position: absolute;
    transform: translate(-50%, -50%);
  }

  .suggested-song-icon {
    width: 25px;
    height: 25px;
    cursor: pointer;
  }

  /* Tooltip Styling */
  .suggested-song[title]:hover::after {
    content: attr(title);
    position: absolute;
    top: -60px;
    left: 50%;
    transform: translateX(-50%);
    white-space: pre-line;
    background-color: rgba(0, 0, 0, 0.8);
    color: #FFF;
    padding: 8px 12px;
    border-radius: 5px;
    z-index: 999;
    width: max-content;
    max-width: 200px;
    text-align: left;
  }

  .suggested-song[title]:hover::before {
    content: '';
    position: absolute;
    top: -10px;
    left: 50%;
    transform: translateX(-50%);
    border-width: 5px;
    border-style: solid;
    border-color: transparent transparent rgba(0, 0, 0, 0.8) transparent;
    z-index: 999;
  }

  /* Style for the Nerd mode switch container */
  .nerd-mode-switch-container {
    margin-top: 20px;
    text-align: center; /* Center the switch horizontally */
  }

  /* Style for the Nerd mode checkbox label */
  .nerd-mode-switch-container .checkbox label {
    font-size: 16px;
    font-weight: 500;
    color: var(--primary-dark);
    cursor: pointer;
  }

  /* Adjust the checkbox appearance */
  .nerd-mode-switch-container .checkbox input[type=\"checkbox\"] {
    margin-right: 8px;
  }

  /* Optional: Style the checkbox itself */
  .nerd-mode-switch-container .checkbox input[type=\"checkbox\"] + label::before {
    content: '';
    display: inline-block;
    width: 16px;
    height: 16px;
    margin-right: 8px;
    border: 1px solid var(--primary-dark);
    border-radius: 4px;
    background-color: #fff;
    vertical-align: middle;
  }

  /* Change appearance when checked */
  .nerd-mode-switch-container .checkbox input[type=\"checkbox\"]:checked + label::before {
    background-color: var(--accent);
    border-color: var(--accent);
  }
")

ui <- navbarPage(
  id = "mainNav",
  inverse = TRUE,
  useShinyjs(),

  # Include the Google Fonts link and custom CSS
  header = tags$head(
    # Embed favicon SVG directly
    HTML('
      <link rel="icon" href="data:image/svg+xml,<svg xmlns=\'http://www.w3.org/2000/svg\' width=\'38\' height=\'67\' viewBox=\'0 0 38 67\' fill=\'none\'><path d=\'M27.503 0C29.9838 0.7121 32.0188 2.73423 33.284 4.93845C35.5627 9.32598 35.678 14.1144 34.2416 18.8C32.1123 24.6745 26.3351 28.0797 20.9968 30.6456C11.0664 35.3777 11.0664 35.3777 4.94734 44.1514C3.58657 48.2062 4.03712 52.6402 5.83505 56.4871C7.30005 59.2111 9.52087 61.8532 11.9482 63.7719C12.3993 64.2914 12.3993 64.2914 12.4946 65.0213C12.3993 65.684 12.3993 65.684 11.9346 66.1482C9.30285 66.0403 7.05987 63.7676 5.32675 61.9559C2.04788 58.2015 -0.164649 53.4592 0.00960685 48.3999C0.671696 41.1091 4.46057 36.0214 10.2672 32.0705C13.6481 29.7568 17.3914 28.1808 20.9959 26.2571C23.9034 24.7097 27.0063 23.2264 28.9408 20.4682C31.0615 17.5848 31.6915 13.9562 31.2208 10.4445C30.5613 7.46041 29.2101 4.52413 26.6906 2.69997C26.3412 2.32099 26.3412 2.32099 26.2531 1.73621C26.3826 0.889421 26.8753 0.548587 27.503 0Z\' fill=\'%23F56C37\'/><path d=\'M29.2685 33.406C33.3006 35.8894 36.1954 39.8312 37.4035 44.4098C37.4575 44.6404 37.4575 44.6404 37.5127 44.8757C37.5521 45.0136 37.5915 45.1516 37.632 45.2937C38.6409 49.8717 37.4911 54.7819 35.2026 58.7433C35.0879 58.943 34.9733 59.1426 34.8551 59.3483C33.411 61.6617 31.5149 63.5617 29.1963 64.9838C29.0093 65.1009 28.8223 65.218 28.6296 65.3386C27.6784 65.9043 27.091 66.2045 25.9622 66.1394C25.6056 65.4259 25.5811 65.0864 25.7312 64.2904C26.2063 63.8403 26.7172 63.4763 27.249 63.0951C28.1144 62.4435 28.7526 61.6652 29.4273 60.8235C29.6137 60.5992 29.8001 60.3748 29.9922 60.1437C31.3424 58.486 32.3517 56.8251 33.1235 54.8142C33.1853 54.6691 33.2472 54.5239 33.3109 54.3744C33.9353 52.7718 33.9194 51.2153 33.9031 49.5127C33.9058 49.2328 33.9085 48.9529 33.9112 48.6645C33.9005 45.3472 32.6854 41.4785 30.3252 39.0135C29.4542 38.2576 28.5433 37.5558 27.618 36.8684C27.2 36.5574 26.7847 36.2426 26.3782 35.9168C24.8573 34.7014 23.0535 33.6213 21.111 33.3193C24.2328 30.7879 26.0548 31.4695 29.2685 33.406Z\' fill=\'%23F56C37\'/><path d=\'M11.0118 0.145117C11.4361 0.696918 11.7045 1.05416 11.6576 1.77952C11.3783 2.49281 10.9352 2.83702 10.3792 3.33239C9.11111 4.46814 8.29494 5.52162 7.60976 7.12747C7.49784 7.38645 7.38592 7.64542 7.27061 7.91224C6.09027 10.8746 6.10201 14.4402 7.18802 17.4602C8.59008 21.0382 10.6344 23.6256 14.0685 25.1782C14.7702 25.4658 15.4735 25.7402 16.1851 25.9991C16.1851 26.3122 16.1851 26.6253 16.1851 26.9479C15.6106 27.2732 15.0343 27.5936 14.456 27.9115C14.2938 28.004 14.1316 28.0964 13.9644 28.1917C12.7667 28.8434 12.7667 28.8434 11.995 28.8519C11.2678 28.5196 10.6705 28.059 10.0559 27.5408C9.92733 27.4336 9.79882 27.3264 9.6664 27.2159C6.10903 24.2026 3.65178 20.3922 2.91438 15.5626C2.55552 10.8527 3.07536 6.57927 5.97903 2.79871C7.12828 1.52038 9.25142 -0.569371 11.0118 0.145117Z\' fill=\'%23F56C37\'/><path d=\'M7.28191 49.9655C7.46041 49.9656 7.6389 49.9657 7.8228 49.9658C8.02762 49.9649 8.23244 49.964 8.44346 49.963C8.66869 49.9643 8.89392 49.9655 9.12598 49.9668C9.48114 49.9662 9.48114 49.9662 9.84348 49.9655C10.6291 49.9647 11.4147 49.9671 12.2003 49.9696C12.7443 49.9698 13.2884 49.9699 13.8324 49.9699C14.9738 49.9702 16.1152 49.9721 17.2566 49.9751C18.7225 49.9788 20.1883 49.9797 21.6541 49.9795C22.7779 49.9796 23.9016 49.9808 25.0254 49.9824C25.566 49.9831 26.1066 49.9835 26.6472 49.9837C27.4017 49.9842 28.1561 49.9861 28.9106 49.9885C29.1358 49.9884 29.361 49.9883 29.5931 49.9882C29.7979 49.9892 30.0027 49.9901 30.2138 49.9911C30.3923 49.9915 30.5708 49.9918 30.7547 49.9922C31.1912 50.0208 31.1912 50.0208 31.6594 50.2432C31.6693 50.6879 31.6689 51.1328 31.6594 51.5775C31.2998 51.9191 30.9685 51.8325 30.4671 51.838C30.2607 51.8409 30.0542 51.8437 29.8415 51.8466C29.4991 51.8496 29.4991 51.8496 29.1498 51.8526C28.9107 51.8555 28.6717 51.8584 28.4255 51.8614C27.631 51.8708 26.8365 51.8784 26.042 51.8859C25.4924 51.8916 24.9428 51.8973 24.3931 51.9031C23.2393 51.9149 22.0855 51.9257 20.9317 51.9361C19.4498 51.9495 17.968 51.966 16.4862 51.9833C15.3506 51.9961 14.2149 52.0069 13.0793 52.017C12.5328 52.0222 11.9863 52.0282 11.4398 52.0349C10.677 52.044 9.9141 52.0503 9.15119 52.0559C8.8095 52.0609 8.8095 52.0609 8.46092 52.0659C8.25379 52.0669 8.04667 52.0678 7.83327 52.0688C7.65274 52.0706 7.47222 52.0723 7.28622 52.0741C6.84539 52.0223 6.84539 52.0223 6.37721 51.5775C6.31868 51.0215 6.31868 51.0215 6.37721 50.4656C6.84539 50.0208 6.84539 50.0208 7.28191 49.9655Z\' fill=\'white\'/><path d=\'M7.01984 45.0375C7.20271 45.0377 7.38558 45.0379 7.57398 45.0382C7.78321 45.0378 7.99243 45.0375 8.208 45.0371C8.4393 45.038 8.67061 45.0389 8.90892 45.0398C9.15111 45.0398 9.39329 45.0398 9.64282 45.0397C10.4476 45.0399 11.2523 45.0419 12.0571 45.0438C12.6134 45.0443 13.1696 45.0447 13.7259 45.0449C15.1934 45.0459 16.6608 45.0483 18.1282 45.0511C19.6243 45.0537 21.1204 45.0548 22.6165 45.0561C25.5544 45.0588 28.4923 45.0631 31.4302 45.0684C31.578 45.7911 31.578 45.7911 31.6667 46.5766C31.1015 47.1774 30.9847 47.1423 30.2155 47.1431C29.9082 47.1453 29.9082 47.1453 29.5946 47.1474C29.3694 47.1464 29.1441 47.1454 28.9119 47.1444C28.5567 47.1457 28.5567 47.1457 28.1942 47.147C27.4084 47.1492 26.6226 47.1478 25.8367 47.1461C25.2925 47.1464 24.7483 47.1469 24.2041 47.1475C23.0623 47.1483 21.9206 47.1472 20.7788 47.1448C19.3125 47.142 17.8463 47.1436 16.38 47.1466C15.2559 47.1485 14.1318 47.1479 13.0076 47.1466C12.4669 47.1462 11.9261 47.1467 11.3853 47.1478C10.6306 47.1491 9.87599 47.1472 9.12129 47.1444C8.89601 47.1454 8.67072 47.1464 8.4386 47.1474C8.23372 47.146 8.02883 47.1446 7.81773 47.1431C7.54991 47.1429 7.54991 47.1429 7.27668 47.1426C6.83946 47.0793 6.83946 47.0793 6.36656 46.5766C6.32223 45.9325 6.32223 45.9325 6.36656 45.3197C6.60301 45.0684 6.60301 45.0684 7.01984 45.0375Z\' fill=\'white\'/><path d=\'M10.0522 55.623C10.2487 55.6238 10.4453 55.6246 10.6478 55.6254C10.9568 55.6253 10.9568 55.6253 11.2719 55.6253C11.9561 55.6254 12.6402 55.6272 13.3243 55.6289C13.7973 55.6293 14.2703 55.6296 14.7433 55.6298C15.9909 55.6307 17.2384 55.6329 18.486 55.6353C19.758 55.6376 21.03 55.6386 22.3019 55.6397C24.7997 55.6421 27.2974 55.6459 29.7951 55.6505C30.0248 56.0896 30.0248 56.0896 30.2591 56.5375C29.4611 57.3528 29.0227 57.6319 27.8267 57.6758C27.4855 57.6778 27.1444 57.6785 26.8033 57.6783C26.6168 57.6791 26.4304 57.6798 26.2383 57.6806C25.6214 57.6827 25.0045 57.6831 24.3876 57.6834C23.9591 57.6841 23.5306 57.6848 23.1021 57.6856C22.2037 57.6869 21.3052 57.6873 20.4067 57.6872C19.255 57.6872 18.1033 57.6902 16.9515 57.694C16.0665 57.6965 15.1814 57.697 14.2964 57.6968C13.8717 57.6971 13.4471 57.6981 13.0224 57.6998C12.4287 57.702 11.8351 57.7013 11.2414 57.7C11.0658 57.7012 10.8902 57.7025 10.7092 57.7038C9.84301 57.6988 9.18676 57.6645 8.45153 57.2027C8.44166 56.7593 8.44206 56.3156 8.45153 55.8723C8.87949 55.4632 9.48279 55.6239 10.0522 55.623Z\' fill=\'white\'/><path d=\'M11.3796 15.5303C11.5592 15.5292 11.7389 15.5281 11.924 15.527C12.5198 15.5238 13.1155 15.5223 13.7112 15.5211C14.1243 15.5199 14.5374 15.5186 14.9505 15.5173C15.8172 15.515 16.6838 15.5138 17.5505 15.513C18.6623 15.5118 19.774 15.5065 20.8857 15.5003C21.7391 15.4962 22.5925 15.4951 23.4459 15.4948C23.8558 15.4941 24.2658 15.4923 24.6757 15.4895C25.2486 15.4857 25.8213 15.4861 26.3941 15.4876C26.6492 15.4845 26.6492 15.4845 26.9095 15.4814C28.0633 15.4905 28.0633 15.4905 28.6194 15.8988C28.6961 16.0055 28.7728 16.1123 28.8518 16.2223C28.4515 17.2894 28.4515 17.2894 27.9368 17.5357C27.3681 17.5583 26.8058 17.5678 26.237 17.5675C25.9742 17.5686 25.9742 17.5686 25.706 17.5697C25.1252 17.5718 24.5443 17.5722 23.9634 17.5724C23.5606 17.5731 23.1577 17.5739 22.7549 17.5746C21.9097 17.5759 21.0646 17.5763 20.2195 17.5762C19.1355 17.5762 18.0514 17.5792 16.9674 17.583C16.1352 17.5854 15.303 17.5858 14.4708 17.5857C14.071 17.586 13.6713 17.5869 13.2716 17.5886C12.713 17.5908 12.1545 17.5902 11.5959 17.5888C11.4301 17.5901 11.2643 17.5913 11.0935 17.5926C10.2511 17.5875 9.90122 17.5578 9.18024 17.0979C9.13735 16.4138 9.13735 16.4138 9.18024 15.7845C9.87987 15.4497 10.6118 15.5314 11.3796 15.5303Z\' fill=\'white\'/><path d=\'M10.9158 9.86177C11.1036 9.86125 11.2915 9.86074 11.485 9.86021C12.1066 9.85945 12.7281 9.8641 13.3496 9.86889C13.7808 9.86965 14.212 9.87013 14.6433 9.87031C15.5471 9.87147 16.4509 9.8751 17.3547 9.88067C18.5151 9.88779 19.6754 9.89053 20.8358 9.89166C21.7262 9.8927 22.6165 9.89517 23.5069 9.89816C23.9348 9.8996 24.3628 9.90079 24.7908 9.90175C25.3879 9.90347 25.985 9.9069 26.5822 9.91087C26.7602 9.91116 26.9382 9.91144 27.1216 9.91173C28.3448 9.92255 28.3448 9.92255 28.8517 10.2028C28.8517 10.7837 28.8517 11.3645 28.8517 11.9629C22.1742 11.9629 15.4967 11.9629 8.61682 11.9629C8.38946 10.7057 8.38946 10.7057 8.60103 10.2556C9.3365 9.78009 10.0878 9.85096 10.9158 9.86177Z\' fill=\'white\'/><path d=\'M9.37455 40.1328C11.8806 40.1288 14.3867 40.1257 16.8928 40.1238C18.0563 40.1229 19.2199 40.1216 20.3834 40.1197C21.5053 40.1178 22.6272 40.1168 23.7491 40.1163C24.1782 40.116 24.6072 40.1154 25.0362 40.1144C25.635 40.1132 26.2337 40.113 26.8324 40.1131C27.0116 40.1125 27.1908 40.1118 27.3755 40.1112C28.5995 40.113 28.5995 40.113 28.8518 40.306C28.7771 40.7062 28.7023 41.1063 28.6253 41.5186C22.1978 41.5186 15.7703 41.5186 9.14807 41.5186C9.14807 40.4792 9.14807 40.4792 9.37455 40.1328Z\' fill=\'white\'/><path d=\'M12.5552 4.93637C12.7097 4.9355 12.8643 4.93462 13.0235 4.93371C13.5354 4.9315 14.0472 4.93297 14.5591 4.93466C14.9141 4.93432 15.2691 4.93384 15.6241 4.93321C16.3685 4.93247 17.113 4.93354 17.8574 4.93588C18.8129 4.93874 19.7683 4.9371 20.7237 4.93409C21.4569 4.93228 22.19 4.93286 22.9232 4.93416C23.2756 4.93449 23.6279 4.93408 23.9803 4.93291C24.4722 4.93164 24.9641 4.93358 25.4561 4.93637C25.8765 4.93697 25.8765 4.93697 26.3054 4.93758C26.9618 5.00125 26.9618 5.00125 27.4231 5.50266C27.4519 6.2861 27.4519 6.2861 27.4231 7.00687C25.2621 7.01267 23.1012 7.01713 20.9403 7.01986C19.9369 7.02117 18.9336 7.02295 17.9303 7.02578C16.9629 7.0285 15.9954 7.03 15.028 7.03066C14.6581 7.03112 14.2882 7.03203 13.9183 7.03338C13.4019 7.03518 12.8856 7.03545 12.3692 7.03533C12.0748 7.03589 11.7803 7.03644 11.4769 7.03702C10.8188 7.00687 10.8188 7.00687 10.5882 6.75617C10.545 6.14508 10.545 6.14508 10.5882 5.50266C11.2366 4.79782 11.647 4.93767 12.5552 4.93637Z\' fill=\'white\'/><path d=\'M11.9631 60.5186C18.9298 60.6282 18.9298 60.6282 26.0372 60.7401C26.0372 60.9594 26.0372 61.1787 26.0372 61.4046C25.8824 61.4046 25.7276 61.4046 25.5681 61.4046C25.5681 61.5508 25.5681 61.697 25.5681 61.8477C24.27 62.622 23.1381 62.6125 21.6528 62.6083C21.4129 62.6094 21.173 62.6106 20.9258 62.6118C20.4201 62.6132 19.9144 62.6129 19.4087 62.611C18.6354 62.6092 17.8625 62.6155 17.0893 62.6226C16.5971 62.6229 16.1049 62.6228 15.6127 62.6221C15.382 62.6246 15.1513 62.6271 14.9136 62.6297C13.9113 62.62 13.2872 62.5899 12.3948 62.1315C11.9631 61.6262 11.9631 61.6262 11.9631 60.5186Z\' fill=\'white\'/></svg>">
    '),
    # Link to the Poppins font
    tags$link(
      href = "https://fonts.googleapis.com/css2?family=Poppins:wght@400&display=swap",
      rel = "stylesheet"
    ),
    # Link to custom CSS
    tags$link(
      href = "custom.css",
      rel = "stylesheet"
    ),
    # Add JavaScript to handle showing/hiding the spinner
    tags$script(HTML("
      Shiny.addCustomMessageHandler('show_spinner', function(show) {
        var spinner = document.getElementById('search-spinner');
        if (show) {
          spinner.style.display = 'block';
        } else {
          spinner.style.display = 'none';
        }
      });
    ")),
    # Add JavaScript to dismiss search results when clicking outside
    tags$script(HTML("
      $(document).on('click', function(event) {
        var $target = $(event.target);
        if (!$target.closest('.search-container').length && !$target.closest('.search-results-dropdown').length) {
          Shiny.setInputValue('hide_search_results', Math.random());
        }
      });
    ")),
    # Add JavaScript for handling clicks on search result items
    tags$script(HTML("
      $(document).on('click', function(event) {
        var $target = $(event.target);
        if (!$target.closest('.search-container').length && !$target.closest('.search-results-dropdown').length) {
          Shiny.setInputValue('hide_search_results', Math.random());
        }
      });

      Shiny.addCustomMessageHandler('setupSearchResultClick', function(message) {
        $(document).off('click', '.search-result-item').on('click', '.search-result-item', function() {
          var songTitle = $(this).attr('data-value');
          Shiny.setInputValue('searchResultClicked', songTitle, {priority: 'event'});
        });
      });
    ")),
    # JavaScript to handle clicks on remove buttons
    tags$script(HTML("
      $(document).on('click', '.remove-song', function() {
        var songTitle = $(this).attr('data-song-title');
        Shiny.setInputValue('remove_song', songTitle, {priority: 'event'});
      });
    ")),
    # JavaScript to handle Analyse button processing state and redirection
    tags$script(HTML("
      Shiny.addCustomMessageHandler('analyseButtonProcessing', function(message) {
        var btn = document.getElementById('analyseBtn');
        if (message.status === 'start') {
          btn.classList.add('processing');
          btn.disabled = true;
          btn.innerHTML = 'Analyse <div class=\"spinner\"></div>';
        } else if (message.status === 'end') {
          btn.classList.remove('processing');
          btn.disabled = false;
          btn.innerHTML = 'Analyse';
          // Redirect to 'Analyse MDNA' page
          $('a[data-value=\"Analyse MDNA\"]').tab('show');
        }
      });
    ")),
    # JavaScript to handle search input click
    tags$script(HTML("
      Shiny.addCustomMessageHandler('setupSearchInputClick', function(message) {
        var searchInput = document.getElementById(message.inputId);
        if (searchInput) {
          searchInput.addEventListener('click', function() {
            Shiny.setInputValue('searchInput_clicked', Math.random());
          });
        }
      });
    ")),
    # Add JavaScript to control tab access
    tags$script(HTML("
      var hasAnalyzed = false;

      // Track analyze button clicks
      $(document).on('click', '#analyseBtn', function() {
        hasAnalyzed = true;
      });

      });

      // Reset when returning to search
      $(document).on('click', 'a[data-value=\"Search Songs\"]', function() {
        hasAnalyzed = false;
      });
    ")),
    # Add JavaScript to handle tab access
    tags$script("
      // Any UI feedback can go here if needed
    "),
    # Add JavaScript to prevent navigation before analysis
    tags$script("
      let hasAnalyzed = false;

      // Track analyze button clicks
      $(document).on('click', '#analyseBtn', function() {
        hasAnalyzed = true;
      });

      // Reset when returning to search
      $(document).on('click', '#mainNav li a[data-value=\"Search Songs\"]', function() {
        hasAnalyzed = false;
      });
    "),
    # Update Font Awesome to use the kit version instead of CDN
    tags$script(
      src = "https://kit.fontawesome.com/your-kit-code.js",  # You'll need a Font Awesome kit code
      crossorigin = "anonymous"
    ),
    # Fallback to CDN if kit is not available
    tags$link(
      rel = "stylesheet",
      href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css",
      integrity = "sha512-iecdLmaskl7CVkqkXNQ/ZH/XLlvWZOJyj7Yy7tcenmpD1ypASozpmT/E0iPtmFIB46ZmdtAc9eNBvH0H/ZpiBw==",
      crossorigin = "anonymous"
    )
  ),

  # Logo and Title Container
  title = div(
    class = "logo-title-container",
    img(src = "assets/logo.svg", class = "logo", alt = "Logo"),
    span("HARMONLY", class = "title-text")
  ),

  # Welcome Page
  tabPanel(
    title = tags$div(
      class = "menu-tab",
      tags$img(src = "assets/search.svg", class = "menu-icon"),
      span("Search songs")
    ),
    value = "Search songs",
    div(
      class = "content-wrapper",
      div(
        class = "welcome-box",
        h1(class = "main-title", "Find out about your Music DNA!"),
        p(
          class = "subtitle",
          "Tell us about the songs you like, and we'll help you discover more music you'll love."
        ),
        # Unified container for search and selected songs
        div(
          class = "input-container",
          div(
            class = "search-container",
            div(
              class = "search-input-wrapper",
              div(
                class = "input-with-spinner",
                tags$input(
                  id = "searchInput",
                  type = "text",
                  placeholder = "Type a song name...",
                  class = "search-input",
                  autocomplete = "off"
                ),
                tags$div(id = "search-spinner", class = "search-spinner", style = "display: none;")
              ),
              uiOutput("searchResults")
            )
          ),
          div(
            class = "matches-container",
            uiOutput("selectedSongs")
          )
        ),
        # Analyse button centered below selected songs
        div(
          class = "analyse-button-container",
          actionButton("analyseBtn", "Analyse", class = "analyse-button")
        ),
        div(
          class = "festive-message",
          div(class = "snow"),
          div(class = "snow"),
          div(class = "snow"),
          div(class = "snow"),
          div(class = "snow"),
          div(class = "snow"),
          div(class = "snow"),
          div(class = "snow"),
          div(class = "snow"),
          div(class = "snow"),
          div(class = "snow"),
          div(class = "snow"),
          tags$img(src = "assets/logo_with_santa_hat_image.png", alt = "Harmonly Santa"),
          tags$p("Tired of the Xmas tunes already? Let's find something else christmassy!")
        )
      )
    )
  ),

  # MDNA Page
  tabPanel(
    title = tags$div(
      class = "menu-tab",
      tags$img(src = "assets/pulse.svg", class = "menu-icon"),
      span("Analyse MDNA")
    ),
    value = "Analyse MDNA",
    div(
      class = "content-wrapper",
      div(
        class = "welcome-box mdna-page",
        h1(class = "main-title", "Your Music DNA!"),
        p(
          class = "subtitle",
          "Here are the songs that are most similar to your current taste."
        ),
        # Placeholder for the MDNA visualization or message
        uiOutput("mdnaContent"),

        # Add the Nerd mode switch here
        div(
          class = "nerd-mode-switch-container",
          div(
            class = "nerd-mode-switch-wrapper",
            # Wrap input and slider in a label
            tags$label(
              class = "nerd-mode-switch",
              # The hidden checkbox input
              tags$input(id = "nerdMode", type = "checkbox"),
              # The slider
              tags$span(class = "slider")
            ),
            # Label for the switch
            tags$span(class = "nerd-mode-switch-label", "Nerd mode!")
          )
        )
      )
    )
  )
)