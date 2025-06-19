document.addEventListener('DOMContentLoaded', function () {
  const sidebar = document.getElementById('sidebar');
  const toggleButton = document.querySelector('.sidebar-toggle');
  const sidebarLinks = sidebar.querySelectorAll('a'); // All links in the sidebar
  const dropdownToggles = sidebar.querySelectorAll('.nav-item.dropdown .nav-link'); // Dropdown toggles

  // Toggle sidebar visibility on button click
  toggleButton.addEventListener('click', function () {
    sidebar.classList.toggle('show');
  });

  // Collapse sidebar when clicking a sidebar link (except dropdown toggles)
  sidebarLinks.forEach(link => {
    link.addEventListener('click', function (event) {
      // Ignore clicks on dropdown toggles
      if (event.target.closest('.nav-item.dropdown')) {
        return;
      }

      // Collapse sidebar only on mobile
      if (window.innerWidth < 992) {
        sidebar.classList.remove('show');
      }
    });
  });

  // Ensure sidebar visibility updates on window resize
  window.addEventListener('resize', function () {
    if (window.innerWidth >= 992) {
      sidebar.classList.add('show'); // Ensure visible on desktop
      sidebar.classList.remove('hide-mobile'); // Remove mobile-only hidden state
    } else {
      sidebar.classList.add('hide-mobile'); // Add mobile-only hidden state
      sidebar.classList.remove('show'); // Ensure hidden on mobile
    }
  });

  // Set initial visibility based on screen size
  if (window.innerWidth >= 992) {
    sidebar.classList.add('show'); // Ensure visible on desktop
    sidebar.classList.remove('hide-mobile'); // Remove mobile-only hidden state
  } else {
    sidebar.classList.add('hide-mobile'); // Add mobile-only hidden state
    sidebar.classList.remove('show'); // Ensure hidden on mobile
  }

  // Dynamic form submission for filters
  const filterElements = document.querySelectorAll('.filter-trigger'); // Filter dropdowns
  const filterForm = document.getElementById('filterForm'); // Filter form

  if (filterElements && filterForm) {
    filterElements.forEach(element => {
      element.addEventListener('change', function () {
        filterForm.submit(); // Submit the form when a filter value changes
      });
    });
  }
});
